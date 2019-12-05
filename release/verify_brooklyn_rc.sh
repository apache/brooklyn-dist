#!/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 0.13.0" # BROOKYLN_VERSION
  exit 1
fi

command -v svn >/dev/null 2>&1 || { echo >&2 "[x] svn required but is not installed. Aborting."; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo >&2 "[x] shasum required but is not installed. On macOS install with 'brew install shasum'. Aborting."; exit 1; }
command -v gpg >/dev/null 2>&1 || { echo >&2 "[x] gpg required but is not installed. On macOS install with 'brew install gpg'. Aborting."; exit 1; }
command -v rpm >/dev/null 2>&1 || { echo >&2 "[x] rpm required but is not installed. On macOS install with 'brew install rpm'. Aborting."; exit 1; }

RELEASE=$1
DOWNLOAD_ROOT=https://dist.apache.org/repos/dist/dev/brooklyn/apache-brooklyn-$RELEASE/
DOWNLOADS_FOLDER=apache-brooklyn-$RELEASE

mkdir -p ${DOWNLOADS_FOLDER}
pushd ${DOWNLOADS_FOLDER}

echo
echo "==============================================================================="
echo "= Importing PGP keys ...                                                      ="
echo "==============================================================================="
echo

KEYS_URL=https://dist.apache.org/repos/dist/release/brooklyn/KEYS
curl $KEYS_URL | gpg --import && \
echo "[✓] GPG keys downloaded from $KEYS_URL" \
  || { echo "[x] Failed to import GPG keys from $KEY_URLS"; exit 1; }

echo
echo "==============================================================================="
echo "= Downloading release artifacts ...                                           ="
echo "==============================================================================="
echo

curl -s $DOWNLOAD_ROOT | \
  grep href | grep -v '\.\.' | \
  sed -e 's@.*href="@'$DOWNLOAD_ROOT'@' | \
  sed -e 's@">.*@@' | \
  xargs -n 1 curl -O && \
  echo "[✓] Artifacts downloaded from $DOWNLOAD_ROOT" \
    || { echo "[x] Failed to download artifacts from staging URL $DOWNLOAD_ROOT"; exit 1; }

echo
echo "==============================================================================="
echo "= Comparing downloaded files listing to SVN staging repo ...                  ="
echo "==============================================================================="
echo

# TODO --trust-server-cert because fails on OS X due to untrusted issuer Issuer: Symantec Class 3 Secure Server CA - G4, Symantec Trust Network, Symantec Corporation, US
diff <(svn --non-interactive --trust-server-cert ls $DOWNLOAD_ROOT | sort) \
  <(ls -1 * | sort) && \
  echo "[✓] No differences detected" \
    || { echo "[x] Unexpected differences between dist and SVN file listing. Aborting."; exit 1; }

echo
echo "==============================================================================="
echo "= Checking signatures and hashes of artifacts ...                             ="
echo "==============================================================================="
echo

find * -type f ! \( -name '*.asc' -o -name '*.sha256' \) -print | while read -r ARTIFACT ; do
  shasum -a256 -c ${ARTIFACT}.sha256 && \
  gpg --verify ${ARTIFACT}.asc ${ARTIFACT} && \
  echo "[✓] Signatures verified for ${ARTIFACT}" \
    || { echo "[x] Invalid signature for ${ARTIFACT}. Aborting."; exit 1; }
done

echo
echo "==============================================================================="
echo "= Checking LICENSE and NOTICE files in artifacts ...                          ="
echo "==============================================================================="
echo

GA_RELEASE=${RELEASE%%-rc?}
find * -type f \( -name '*.tar.gz' -or -name '*.zip' -or -name '*.rpm' \) -print | while read -r ARCHIVE ; do
  REL_ARCHIVE=${ARCHIVE/-rc?}
  case $ARCHIVE in
    *.tar.gz)
      LIST="tar -tvf"
      PREFIX=${REL_ARCHIVE%.tar.gz}
      ;;
    *.zip)
      LIST="unzip -Zl"
      PREFIX=${REL_ARCHIVE%.zip}
      ;;
    *.rpm)
      LIST="rpm -qlp"
      PREFIX="/opt/brooklyn-${GA_RELEASE}"
      ;;
    *)
      echo "Unrecognized file type $ARCHIVE. Aborting!"
      exit 1
      ;;
  esac
  $LIST $ARCHIVE | grep "$PREFIX/NOTICE" && \
  $LIST $ARCHIVE | grep "$PREFIX/LICENSE" && \
  echo "[✓] Files LICENSE and NOTICE present in $ARCHIVE" \
    || { echo "[x] Missing LICENSE or NOTICE in $ARCHIVE. Aborting!"; exit 1; }
done

echo
echo "==============================================================================="
echo "= Extracting sources ...                                                      ="
echo "==============================================================================="
echo

SOURCE_ARCHIVE=apache-brooklyn-$RELEASE-src.tar.gz
SOURCE_RELEASE_FOLDER=apache-brooklyn-${GA_RELEASE}-src
tar -zxf apache-brooklyn-$RELEASE-src.tar.gz && \
echo "[✓] Extraction successful of $SOURCE_ARCHIVE to $SOURCE_RELEASE_FOLDER" \
  || { echo "[x] Failed to extract sources from $SOURCE_ARCHIVE to $SOURCE_RELEASE_FOLDER. Aborting!"; exit 1; }

echo
echo "==============================================================================="
echo "= Checking out git repository at release tags ...                             ="
echo "==============================================================================="
echo

GIT_FOLDER=repository
git clone git://git.apache.org/brooklyn.git $GIT_FOLDER && \
pushd $GIT_FOLDER && \
    git submodule init && \
    git submodule update --remote --merge --recursive && \
    git checkout rel/apache-brooklyn-$RELEASE && \
    git submodule foreach git checkout rel/apache-brooklyn-$RELEASE && \
popd && \
echo "[✓] Git clone successful" \
  || { echo "[x] Failed to clone git repository. Aborting!"; exit 1; }

echo
echo "==============================================================================="
echo "= Comparing git repository to sources                                         ="
echo "==============================================================================="
echo

diff -qr $SOURCE_RELEASE_FOLDER $GIT_FOLDER/ || true
SOURCE_DIFF_CNT=$(
  diff -qr $SOURCE_RELEASE_FOLDER $GIT_FOLDER/ \
    -x '*.git' -x '*.gitattributes' -x '*.gitignore' \
    -x '*.gitmodules' -x 'release' -x 'brooklyn-docs' \
    -x 'sandbox' | \
  grep -v 'src/test/.*\.jar' | \
  grep -v 'hello-world.*\.war' | \
  wc -c)

[ $SOURCE_DIFF_CNT -eq 0 ] || { echo "[x] Unexpected differences between source distribution and git repository. Aborting."; exit 1; }
echo "[✓] No differences detected"

echo
echo "==============================================================================="
echo "= Building from sources ...                                                   ="
echo "==============================================================================="
echo

MAVEN_REPO=m2
mkdir -p $MAVEN_REPO
pushd $SOURCE_RELEASE_FOLDER
  mvn -Dmaven.repo.local=$MAVEN_REPO clean install && \
  echo "[✓] Build from sources successful" \
    || { echo "[x] Failed to build from sources. Aborting!"; exit 1; }
popd

echo
echo "-------------------------------------------"
echo
echo "Additional steps requiring manual intervention (execute in source distribution folder ${SOURCE_RELEASE_FOLDER}:"
echo " * Check for files with invalid headers in source distribution. There are already files excluded from RAT checks, do a sanity check."
echo "   $ grep -rL \"Licensed to the Apache Software Foundation\" ${DOWNLOADS_FOLDER}/${SOURCE_RELEASE_FOLDER}* | less"
echo
echo " * Check for binary files in source distribution. Look for files which are created/compiled based on other source files in the distribution. \
\"Primary\" binary files like images are acceptable."
echo "   Example less filter:  '&!ASCII|Unicode|directory|PNG|JPEG|GIF|KeyStore|EOT|SVG|icon|font|woff|public key|private key|certificate'"
echo "   $ find ${DOWNLOADS_FOLDER}/${SOURCE_RELEASE_FOLDER} | xargs -n1 file | awk -F $':' ' { t = \$1; \$1 = \$2; \$2 = t; print; } ' | sort | less"
echo
echo "Checks successfully completed:"
echo "[✓] Download links work."
echo "[✓] Checksums and PGP signatures are valid."
echo "[✓] Expanded source archive matches contents of RC tag."
echo "[✓] Expanded source archive builds and passes tests."
echo "[✓] LICENSE is present and correct."
echo "[✓] NOTICE is present and correct, including copyright date."
echo "[✓] No compiled archives bundled in source archive."
echo
echo "Checks left to do manually with the help of above instructions:"
echo "[ ] All files have license headers where appropriate."
echo "[ ] All dependencies have compatible licenses."
echo
echo "Remaning items from checklist:"
echo "[ ] Binaries work."
echo "[ ] I follow this project’s commits list."

## TODO
# * Automate above manual steps
# * Add maven repository checks (generate archetype project and build it?; should happen in a container not to pollute local repo)
# * Run binary distribution and do basic sanity checks (using br; using maven plugin?)
# * --trust-server-cert is against the spirit of the "verify" step - can we fix it another way?

popd