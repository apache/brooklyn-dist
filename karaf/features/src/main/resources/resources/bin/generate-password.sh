#!/bin/bash
#
################################################################################
#
#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
################################################################################


usage() {
    echo "Usage: $0 -u <user> [--salt <salt>]" 1>&2
    exit 1
}

generateSalt() {
    # For explanation of LC_TYPE, see
    # https://unix.stackexchange.com/questions/45404/why-cant-tr-read-from-dev-urandom-on-osx
    echo "$(LC_CTYPE=C tr -dc "A-Za-z0-9" < /dev/urandom | head -c 4)"
}

checkCanGenerateHash() {
    if ! ( type sha256sum >/dev/null 2>&1 || type shasum >/dev/null 2>&1 ); then
         echo "No sha256sum or shasum tool available." 1>&2
         echo "Please install one of these tools, and retry." 1>&2
         exit 1
     fi
 }

generateHash() {
    local __input=${1}
    if type sha256sum >/dev/null 2>&1; then
        echo "$(echo -n "${__input}" | sha256sum | awk '{print $1}')"
    elif type shasum >/dev/null 2>&1; then
        echo "$(echo -n "${__input}" | shasum -a 256 | awk '{print $1}')"
    else
        # Should have been detected earlier with checkCanGenerateHash
        echo "No sha256sum or shasum tool available." 1>&2
        echo "Please install one of these tools, and retry." 1>&2
        exit 1
    fi
}

checkCanGenerateHash

while getopts ":u:-:" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                user)
                    user="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                salt)
                    salt="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    if [ -z "${salt}" ]; then
                        usage
                    fi
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        u)
            user=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${user}" ]; then
    usage
fi

if [ -z "${salt}" ]; then
    salt=$(generateSalt)
fi

echo -n Password:
read -s password
echo
echo -n Re-enter password:
read -s password2
echo
echo

if [ "${password}" != "${password2}" ]; then
    echo "Passwords do not match" 1>&2
    exit 1
fi

if [ -z "${password}" ]; then
    echo "Password must not be blank" 1>&2
    exit 1
fi

hash=$(generateHash "${salt}${password}")

echo "Please add the following to your etc/brooklyn.cfg:"
echo
echo brooklyn.webconsole.security.users=${user}
echo brooklyn.webconsole.security.user.${user}.salt=${salt}
echo brooklyn.webconsole.security.user.${user}.sha256=${hash}

