#!/usr/bin/env bash
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

release_script_dir=$( cd $( dirname $0 ) && pwd )
[ -f "${release_script_dir}/common.sh" ] || {
    echo >&2 "Could not find common.sh in the same directory as this script"
    exit 1
}
. "${release_script_dir}/common.sh"

###############################################################################
show_help() {
    cat >&2 <<END
Usage: make-release-artifacts.sh [-v version] [-r rc_number]
Outputs the environment variable settings recommended in the release process
documentation.

  -cVERSION                  overrides the name of the current version, if
                             detection from pom.xml is not accurate for any
                             reason.
  -vVERSION                  the version to release. Defaults to the current
                             versions with the -SNAPSHOT suffix removed.
  -rRC_NUMBER                specifies the release candidate number.
  -dVERSION                  the version to continue with on the development
                             branch. Defaults to a sensible guess as to the
                             next version with a -SNAPSHOT suffix.

Typical usage of this script would be:
    eval $( ./environment.sh <options...> )
This would cause the environment variables to be set in the current shell.
END
# ruler                      --------------------------------------------------
}

###############################################################################
# Argument parsing
rc_suffix=
OPTIND=1
while getopts "h?v:r:c:" opt; do
    case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        c)
            current_version=$OPTARG
            ;;
        v)
            release_version=$OPTARG
            ;;
        r)
            rc_suffix=$OPTARG
            ;;
        d)
            continue_version=$OPTARG
            ;;
        *)
            show_help
            exit 1
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

detect_version

if [ -z "${release_version}" ]; then
    release_version=${current_version%-SNAPSHOT}
    [ "${release_version}" = "${current_version}" ] && fail Could not detect release version. Please provide using the -v option.
else
    [ "${release_version}" = "${current_version}" ] && { echo >&2 The provided release version is the same as the current version.; confirm || exit; }
fi

if [ -z "${continue_version}" ]; then
    continue_version=$( perl -e 'die unless "'"$current_version"'" =~ /^(\d+)\.(\d+)\.(\d+)(.*)$/; printf "%d.%d.0-SNAPSHOT\n", $1, $2+1' ) || fail Could not detect the continuing version. Please provide using the -d option.
else
    [ "${continue_version}" = "${current_version}" ] && { echo >&2 The provided continue version is the same as the current version.; confirm || exit; }
    [ "${continue_version}" = "${release_version}" ] && { echo >&2 The provided continue version is the same as the release version.; confirm || exit; }
fi

echo >&2 "The current version is: ${current_version}"
echo >&2 "The release version is: ${release_version} release candidate ${rc_suffix}"
echo >&2 "The continuing version is: ${continue_version}"
confirm || exit

cat <<EOF
OLD_MASTER_VERSION=${current_version}
NEW_MASTER_VERSION=${continue_version}
VERSION_NAME=${release_version}
RC_NUMBER=${rc_suffix}
SUBMODULES="$( perl -n -e 'if ($_ =~ /path += +(.*)$/) { print $1." " }' < .gitmodules )"
MODULES=". \${SUBMODULES}"
EOF
