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
  echo "Usage: $0 0.10.0-rc3"
  exit 1
fi

command -v svn >/dev/null 2>&1 || { echo >&2 "svn required but is not installed.  Aborting."; exit 1; }
command -v md5sum >/dev/null 2>&1 || { echo >&2 "md5sum required but is not installed. On macOS install with 'brew install md5sha1sum'. Aborting."; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo >&2 "shasum required but is not installed. On macOS install with 'brew install md5sha1sum'. Aborting."; exit 1; }
command -v gpg2 >/dev/null 2>&1 || { echo >&2 "gpg2 required but is not installed. On macOS install with 'brew install gnupg2'. Aborting."; exit 1; }

RELEASE=$1
DOWNLOAD_ROOT=https://dist.apache.org/repos/dist/dev/brooklyn/apache-brooklyn-$RELEASE/
DOWNLOADS_FOLDER=apache-brooklyn-$RELEASE

mkdir ${DOWNLOADS_FOLDER}
cd ${DOWNLOADS_FOLDER}

echo
echo "======================"
echo "= Importing PGP keys ="
echo "======================"
echo
echo "Downloading KEYS from https://dist.apache.org/repos/dist/release/brooklyn/KEYS"
curl -s https://dist.apache.org/repos/dist/release/brooklyn/KEYS | gpg --import

echo
echo "============================="
echo "= Downloading release files ="
echo "============================="
echo
echo "Downloading from staging URL $DOWNLOAD_ROOT"
curl -s $DOWNLOAD_ROOT | \
  grep href | grep -v '\.\.' | \
  sed -e 's@.*href="@'$DOWNLOAD_ROOT'@' | \
  sed -e 's@">.*@@' | \
  xargs -n 1 curl -O

echo
echo "========================================================"
echo "= Compare downloaded files listing to SVN staging repo ="
echo "========================================================"
echo
# TODO --trust-server-cert because fails on OS X due to untrusted issuer Issuer: Symantec Class 3 Secure Server CA - G4, Symantec Trust Network, Symantec Corporation, US
diff <(svn --non-interactive --trust-server-cert ls https://dist.apache.org/repos/dist/dev/brooklyn/apache-brooklyn-$RELEASE | sort) \
  <(ls -1 * | sort)
echo "OK"

echo
echo "==================================================="
echo "= Check signatures and hashes of downloaded files ="
echo "==================================================="
echo
for artifact in $(find * -type f ! \( -name '*.asc' -o -name '*.md5' -o -name '*.sha1' -o -name '*.sha256' \) ); do
  md5sum -c ${artifact}.md5 && \
  shasum -a1 -c ${artifact}.sha1 && \
  shasum -a256 -c ${artifact}.sha256 && \
  gpg2 --verify ${artifact}.asc ${artifact} \
    || { echo "Invalid signature for $artifact. Aborting!"; exit 1; }
done

echo
echo "=================================================="
echo "= Check for LICENSE and NOTICE files in archives ="
echo "=================================================="
echo
for ARCHIVE in $(find * -type f ! \( -name '*.asc' -o -name '*.md5' -o -name '*.sha1' -o -name '*.sha256' \) ); do
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
      PREFIX="/opt/brooklyn"
      ;;
    *)
      echo "Unrecognized file type $ARCHIVE. Aborting!"
      exit 1
      ;;
  esac
  $LIST $ARCHIVE | grep "$PREFIX/NOTICE" && \
  $LIST $ARCHIVE | grep "$PREFIX/LICENSE" \
    || { echo "Missing LICENSE or NOTICE in $ARCHIVE. Aborting!"; exit 1; } 
done

echo
echo "========================="
echo "= Extract source folder ="
echo "========================="
echo
tar -zxf apache-brooklyn-$RELEASE-src.tar.gz
GA_RELEASE=${RELEASE%%-rc?}
SOURCE_RELEASE_FOLDER=apache-brooklyn-${GA_RELEASE}-src
echo "OK"

echo
echo "======================================="
echo "= Checkout repository at release tags ="
echo "======================================="
echo
git clone git://git.apache.org/brooklyn.git repository
cd repository
git submodule init
git submodule update --remote --merge --recursive
git checkout rel/apache-brooklyn-$RELEASE 
git submodule foreach git checkout rel/apache-brooklyn-$RELEASE
cd ..

echo
echo "========================================"
echo "= Compare repository to source release ="
echo "========================================"
echo
diff -qr ${SOURCE_RELEASE_FOLDER} repository/ || true
SOURCE_DIFF_CNT=$(
  diff -qr ${SOURCE_RELEASE_FOLDER} repository/ \
    -x '*.git' -x '*.gitattributes' -x '*.gitignore' \
    -x '*.gitmodules' -x 'release' -x 'brooklyn-docs' \
    -x 'sandbox' | \
  grep -v 'src/test/.*\.jar' | \
  grep -v 'hello-world.*\.war' | \
  wc -c)

[ ${SOURCE_DIFF_CNT} -eq 0 ] || { echo "Unexpected differences between source distribution and repository. Aborting!"; exit 1; }
echo
echo "Didn't find unexpected differences."

echo
echo "======================"
echo "= Build from sources ="
echo "======================"
echo
cd ${SOURCE_RELEASE_FOLDER};
mvn -Dmaven.repo.local=../maven-sandbox-repo clean install
cd ..;

echo
echo "Do a clean extract of source repo for next steps."
rm -rf ${SOURCE_RELEASE_FOLDER};
tar -zxf apache-brooklyn-$RELEASE-src.tar.gz
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
