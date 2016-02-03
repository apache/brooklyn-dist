#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# displays a summary list of commits in your current repo vs upstream branch and upstream master,
# and of working tree changes Added, Modified, Deleted, or not in index ("??")

THIS_COMMAND="$0 $@"

while true; do
  case $1 in
    -o|--offline)
      OFFLINE=true
      ;;
    -r|--recurse|--recursive)
      RECURSE=true
      ;;
    -m|--master)
      shift
      UPSTREAM_MASTER=$1
      MASTER_UPSTREAM_REPO=`echo $1 | cut -d / -f 1`
      ;;
    -h|--help)
      cat <<EOF
Usage: git-summary [--help] [-o|--offline] [-r|--recursive] [-m|--master REPO/BRANCH] [<path>]"

This will display a one-line git log for differences between the local branch, the upstream 
repo and branch of the local branch, and the upstream/master or origin/master branch.  

The following prefixes are shown on commits:

  < means in upstream/master but not in your upstream branch (your upstream is behind master)
  > means in your upstream branch but not in upstream/master (your upstream is ahead of master)
  ^ means in your upstream branch but not locally (consider a pull)
  * means local but not in the upstream branch (consider a push)

The optional <path> one or more files or paths to look at.

The following options are supported:

  -o  to operate offline, skipping the fetch done by default (aka --offline)
  -r  to recurse (aka --recurs{e,ive})
  -m  to specify a master "repo/branch" to compare upstream with, or "" for none (aka --master);
      defaults to "upstream/master" or "origin/master" (the first existing)
 

EOF
      exit 1
      ;;
    *)
      break
      ;;
    esac
    shift || break
done

# assume master is upstream/master or origin/master
[ -n "${MASTER_UPSTREAM_REPO}" ] || \
  MASTER_UPSTREAM_REPO=upstream && git config remote.${MASTER_UPSTREAM_REPO}.url > /dev/null || \
  MASTER_UPSTREAM_REPO=origin && git config remote.${MASTER_UPSTREAM_REPO}.url > /dev/null || \
  unset MASTER_UPSTREAM_REPO
[ -z "${MASTER_UPSTREAM_REPO}" ] || \
  [ -n "${UPSTREAM_MASTER}" ] || UPSTREAM_MASTER=${MASTER_UPSTREAM_REPO}/master
[ -z "${MASTER_UPSTREAM_REPO}" ] || [ -n "${OFFLINE}" ] || \
  git fetch ${MASTER_UPSTREAM_REPO}

THIS_BRANCH_NAME=$(git symbolic-ref --short -q HEAD)
if [ -z "${THIS_BRANCH_NAME}" ] ; then
  THIS_BRANCH_NAME="(DETACHED)"
  unset THIS_UPSTREAM_BRANCH
else
  THIS_UPSTREAM_BRANCH=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
  THIS_UPSTREAM_BRANCH_REPO=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD) | cut -f 1 -d '/')
  # fetch the branch's upstream repo if different to the master
  [ -n "${OFFLINE}" ] || [ -z "${THIS_UPSTREAM_BRANCH_REPO}" ] || [ "${THIS_UPSTREAM_BRANCH_REPO}" == "${MASTER_UPSTREAM_REPO}" ] || git fetch ${THIS_UPSTREAM_BRANCH_REPO}
fi
[ \! -z "${THIS_UPSTREAM_BRANCH}" ] && THIS_UPSTREAM_BRANCH_NAME="${THIS_UPSTREAM_BRANCH}" || THIS_UPSTREAM_BRANCH_NAME="(no upstream)"

TMP=/tmp/git-summary-$(uuidgen)
rm -f ${TMP}-*
touch ${TMP}-{1-master-ahead,2-master-behind,3-up,4-local}

if [ -z "${UPSTREAM_MASTER}" -a -z "$THIS_UPSTREAM_BRANCH" ] ; then
  true # nothing to do
elif [ "${UPSTREAM_MASTER}" == "$THIS_UPSTREAM_BRANCH" -o -z "$THIS_UPSTREAM_BRANCH" ] ; then
  [ -z "${UPSTREAM_MASTER}" ] || git log --pretty=" ^ %h %aN, %ar: %s" ..${UPSTREAM_MASTER} "$@" > ${TMP}-3-up
  [ -z "${UPSTREAM_MASTER}" ] || git log --pretty=" * %h %aN, %ar: %s" ${UPSTREAM_MASTER}.. "$@" > ${TMP}-4-local
else
  [ -z "${UPSTREAM_MASTER}" ] || git log --pretty=" < %h %aN, %ar: %s" $THIS_UPSTREAM_BRANCH..${UPSTREAM_MASTER} "$@" > ${TMP}-1-master-ahead
  [ -z "${UPSTREAM_MASTER}" ] || git log --pretty=" > %h %aN, %ar: %s" ${UPSTREAM_MASTER}..$THIS_UPSTREAM_BRANCH "$@" > ${TMP}-2-master-behind
  git log --pretty=" ^ %h %aN, %ar: %s" ..$THIS_UPSTREAM_BRANCH "$@" > ${TMP}-3-up
  git log --pretty=" * %h %aN, %ar: %s" $THIS_UPSTREAM_BRANCH.. "$@" > ${TMP}-4-local
fi
git status --porcelain --ignore-submodules "$@" > ${TMP}-5-commits
cat ${TMP}-* > ${TMP}
if [ -s ${TMP} ] ; then
  AHEAD=$(wc ${TMP}-1-* | awk '{print $1}')
  BEHIND=$(wc ${TMP}-2-* | awk '{print $1}')
  UP=$(wc ${TMP}-3-* | awk '{print $1}')
  LOCAL=$(wc ${TMP}-4-* | awk '{print $1}')
  [ "${AHEAD}" == "0" ] || COUNTS="upstream ${AHEAD} behind master"
  [ "${BEHIND}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }upstream ${BEHIND} ahead of master"
  [ "${UP}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }local ${UP} behind"
  [ "${LOCAL}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }local ${LOCAL} unpushed"
  echo $(basename $(pwd))": ${THIS_BRANCH_NAME} <- ${THIS_UPSTREAM_BRANCH_NAME} (${COUNTS:-uncommitted changes only})"
  cat ${TMP} | sed 's/^/ /'
else
  echo $(basename $(pwd))": ${THIS_BRANCH_NAME} <- ${THIS_UPSTREAM_BRANCH_NAME} (up to date)"
fi
rm -f ${TMP} ${TMP}-*

# submodules ignored; if using them, set up

if [ "$RECURSE" ] ; then
  echo
  git submodule --quiet foreach --recursive "${THIS_COMMAND}"
fi

