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
pull source of the local branch, and the push target of the local branch.  With the "central"
(one-repo) workflow the latter two are the same (and you won't see < or > below).
In a triangle workflow, these might be `master`, `upstream/master`, and `origin/master`
(or `your_github_id/master` instead of `origin`). See `man git-config` pages on `push.default`
and `remote.pushDefault` for help configuring triangle workflow. Or use these names and
the script will do the right thing!

The following prefixes are shown on commits which are in some but not all locations:

  * local change, not in either the pull or push upstream (do a git push, then open a pull request)
  > changes not yet upstream, in your push upstream but not your pull upstream (open a pull request)
  ^ someone else's change, in your pull upstream but not local (do a git pull to update)
  < someone else's change, local but not in the push upstream (do a git push to update)

The optional <path> can be used to specify one or more files or paths to look at.

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

# find pull and push sources using canonical git commands
[ -n "${PULL_BRANCH}" ] || \
  PULL_BRANCH=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)) && \
    git show $PULL_BRANCH > /dev/null 2> /dev/null || \
  unset PULL_BRANCH && true

[ -n "${PUSH_BRANCH}" ] || \
  PUSH_BRANCH=$(git for-each-ref --format='%(push:short)' $(git symbolic-ref -q HEAD)) && \
    git show $PUSH_BRANCH > /dev/null 2> /dev/null || \
  unset PUSH_BRANCH && true

# attempt some inferencing if the above didn't work
# or if pulling and pushing from same repo, see if others are available
# (remove this if you normally use central workflow)

if [ "${PULL_BRANCH}" == "${PUSH_BRANCH}" ] ; then
  [ "${PULL_BRANCH#upstream/}" == "${PULL_BRANCH}" ] || unset PUSH_BRANCH
  [ "${PULL_BRANCH#origin/}" == "${PULL_BRANCH}" ] || unset PULL_BRANCH
fi

[ -n "${PULL_REPO}" ] || \
  { [ -n "${PULL_BRANCH}" ] && PULL_REPO=$(echo $PULL_BRANCH | cut -f 1 -d '/') ; } || \
  PULL_REPO=upstream && git config remote.${PULL_REPO}.url > /dev/null || \
  PULL_REPO=origin && git config remote.${PULL_REPO}.url > /dev/null || \
  unset PULL_REPO

# set default PULL BRANCH if needed
[ -z "${PULL_REPO}" ] || [ -n "${PULL_BRANCH}" ] || \
  PULL_BRANCH=${PULL_REPO}/master

[ -z "${PULL_REPO}" ] || [ -n "${OFFLINE}" ] || \
  git fetch ${PULL_REPO}

[ -n "${PUSH_REPO}" ] || \
  { [ -n "${PUSH_BRANCH}" ] && PUSH_REPO=$(echo $PUSH_BRANCH | cut -f 1 -d '/') ; } || \
  PUSH_REPO=origin && git config remote.${PUSH_REPO}.url > /dev/null || \
  unset PUSH_REPO

# set default PUSH BRANCH if needed
[ -z "${PUSH_REPO}" ] || [ -n "${PUSH_BRANCH}" ] || \
  PUSH_BRANCH=${PUSH_REPO}/master


THIS_BRANCH_DISPLAY_NAME=$(git symbolic-ref --short -q HEAD)

if [ -z "${THIS_BRANCH_DISPLAY_NAME}" ] ; then
  THIS_BRANCH_DISPLAY_NAME="(DETACHED)"
  unset PUSH_BRANCH
else
  PUSH_REPO=$(echo $PUSH_BRANCH | cut -f 1 -d '/')
  # fetch the branch's upstream repo if different to the master
  [ -n "${OFFLINE}" ] || [ -z "${PUSH_REPO}" ] || [ "${PUSH_REPO}" == "${PULL_REPO}" ] || git fetch ${PUSH_REPO}
fi
[ -n "${PUSH_BRANCH}" ] && PUSH_BRANCH_DISPLAY_NAME="${PUSH_BRANCH}" || PUSH_BRANCH_DISPLAY_NAME="(no upstream)"
[ -n "$PUSH_BRANCH}" ] || PUSH_BRANCH=${PULL_BRANCH}
[ -n "$PULL_BRANCH}" ] || PULL_BRANCH=${PUSH_BRANCH}

TMP=/tmp/git-summary-$(uuidgen)
rm -f ${TMP}-*
touch ${TMP}-{1-master-ahead,2-master-behind,3-up,4-local}

# basically there are 6 modes where a commit is not in all three repos
# * pull ahead - show < and ^ - IMPORTANT means new commits we must get
# * pull behind - show > - IMPORTANT means PR not yet merged
# * push ahead - show > - WEIRD means someone else pushed to our origin
# * push behind - show < and * - means push needed to bring origin back into sync - but filter * specially
# * local ahead - show * - IMPORTANT means new commits we must push
# * local behind - show ^ - WEIRD means someone else pushed to our origin

if [ -z "${PULL_BRANCH}" ] ; then
  true # nothing to do
else
  if [ "${PULL_BRANCH}" != "${PUSH_BRANCH}" ] ; then
    git log --pretty=" < %h %aN, %ar: %s" ${PUSH_BRANCH}..${PULL_BRANCH} "$@" >> ${TMP}-1-master-ahead
    git log --pretty=" > %h %aN, %ar: %s" ${PULL_BRANCH}..$PUSH_BRANCH "$@" >> ${TMP}-2-master-behind
  fi

  git log --pretty=" ^ %h %aN, %ar: %s" ..${PULL_BRANCH} "$@" >> ${TMP}-3-pull-ahead-of-local
  cat ${TMP}-3-pull-ahead-of-local | while read line ; do
    word=$(echo "$line" | awk '{print $2}')
    if grep $word ${TMP}-1-master-ahead > /dev/null 2> /dev/null ; then
      sed -i .bak "s/ < $word/<^ $word/" ${TMP}-1-master-ahead
    else
      # only write to local if not in pull
      echo " $line" >> ${TMP}-3-up
    fi
  done

  git log --pretty=" * %h %aN, %ar: %s" ${PUSH_BRANCH}.. "$@" >> ${TMP}-4-local-ahead-of-push
  cat ${TMP}-4-local-ahead-of-push | while read line ; do
    word=$(echo "$line" | awk '{print $2}')
    if grep $word ${TMP}-1-master-ahead > /dev/null 2> /dev/null ; then
      sed -i .bak "s/ < $word/<* $word/" ${TMP}-1-master-ahead
    else
      # only write to local if not in pull
      echo " $line" >> ${TMP}-4-local
    fi
  done
  rm ${TMP}-3-pull-ahead-of-local
  rm ${TMP}-4-local-ahead-of-push
  rm ${TMP}-1-*.bak
fi
git status --porcelain --ignore-submodules "$@" > ${TMP}-5-commits
cat ${TMP}-* > ${TMP}

# TODO unreliable way to get project name
SUMMARY=$(basename $(pwd))

# append files if needed
[ -z "$1" ] || SUMMARY="${SUMMARY} ($@)"

SUMMARY="${SUMMARY}: ${THIS_BRANCH_DISPLAY_NAME} -> ${PUSH_BRANCH_DISPLAY_NAME}"
[ -z ${PULL_BRANCH} ] || [ "${PULL_BRANCH}" == "${PUSH_BRANCH}" ] ||
  SUMMARY=${SUMMARY}" -> ${PULL_BRANCH}"

if [ -s ${TMP} ] ; then
  AHEAD=$(wc ${TMP}-1-* | awk '{print $1}')
  BEHIND=$(wc ${TMP}-2-* | awk '{print $1}')
  UP=$(wc ${TMP}-3-* | awk '{print $1}')
  LOCAL=$(wc ${TMP}-4-* | awk '{print $1}')
  [ "${AHEAD}" == "0" ] || COUNTS="push target ${AHEAD} behind upstream"
  [ "${BEHIND}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }upstream ${BEHIND} behind push target"
  [ "${UP}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }local ${UP} behind"
  [ "${LOCAL}" == "0" ] || COUNTS="${COUNTS}${COUNTS:+, }local ${LOCAL} unpushed"
  echo "${SUMMARY} (${COUNTS:-uncommitted changes only})"
  cat ${TMP} | sed 's/^/ /'
else
  echo "${SUMMARY} (all up to date)"
fi
rm -f ${TMP} ${TMP}-*

# submodules ignored; if using them, set up

if [ "$RECURSE" ] ; then
  echo
  git submodule --quiet foreach --recursive "${THIS_COMMAND}"
fi

