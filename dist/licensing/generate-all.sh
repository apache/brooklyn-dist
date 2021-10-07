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

set -e

usage() {
  cat >&2 << EOF

Usage:  generate-all.sh

Execute generate-license-and-notice.sh to generate LICENSE and NOTICE files for all Brooklyn projects.

EOF
}

while [ ! -z "$*" ] ; do

  if [ "$1" == "--help" ]; then usage ; exit 0; fi
  if [ "$1" == "--loadonly" ]; then
    LOAD_ONLY=true
    shift
    continue
  fi

  usage
  echo Unexpected argument: $1
  exit 1 

done

REF_DIR=$(pushd $(dirname $BASH_SOURCE) > /dev/null ; pwd -P ; popd > /dev/null)
if [ -z "$PARTS_DIR" ] ; then PARTS_DIR=$REF_DIR/parts ; fi
ROOT_DIR=$REF_DIR/../../..
MVN_OUTFILE=$REF_DIR/notices.autogenerated

prefix_and_join_array() {
  PREFIX=$2
  JOIN_BEFORE_PREFIX=$1
  JOIN_AFTER_PREFIX=$3
  echo -n "${PREFIX}$4"
  shift 4
  while (($#  >= 1)) ; do
    echo -n "${JOIN_BEFORE_PREFIX}${PREFIX}${JOIN_AFTER_PREFIX}$1"
    shift
  done
}

# takes a base dir in first arg, then sub-project dir to build, then output, mode, then search root relative to output dir 
make_for() {
  BASE=$(cd $1 ; pwd -P)
  PROJ=$(cd $BASE ; cd $2; pwd -P)
  OUT=$(cd $BASE ; cd $3; pwd -P)
  MODE=$4
  SEARCH_ROOT=$5
  if [ -z "$SEARCH_ROOT" ] ; then SEARCH_ROOT=. ; fi
  SEARCH_ROOT=$(cd $BASE ; cd $SEARCH_ROOT; pwd -P)
  ARGS=$6

  echo Generating for $PROJ mode $MODE to $OUT...
  echo ""
  
  pushd $PROJ > /dev/null
  
  if [ "$MODE" == "source-then-additional-binary" ] ; then

    $REF_DIR/generate-license-and-notice.sh \
      -o $OUT \
      --license $PARTS_DIR/license-top \
      --license $PARTS_DIR/license-deps-with-additional-binary \
      --notice $PARTS_DIR/notice-top-with-additional-binary --notice-compute-with-flags "
        -DextrasFiles=$(prefix_and_join_array "" ":" "" $(find -L $SEARCH_ROOT -name "license-inclusions-source-*"))
        -DonlyExtras=true" \
      --notice $PARTS_DIR/notice-additional-binary --notice-compute-with-flags "
        -DextrasFiles=$(prefix_and_join_array "" ":" "" $(find -L $SEARCH_ROOT -name "license-inclusions-binary-*"))" \
      $ARGS \
      --libraries ${REF_DIR} ${SEARCH_ROOT} 
    
  elif [ "$MODE" == "binary" ] ; then

    $REF_DIR/generate-license-and-notice.sh \
      -o $OUT \
      --license $PARTS_DIR/license-top \
      --license $PARTS_DIR/license-deps \
      --notice $PARTS_DIR/notice-top --notice-compute-with-flags "
        -DextrasFiles=$(prefix_and_join_array "" ":" "" $(find -L $SEARCH_ROOT -name "license-inclusions-source-*" -or -name "license-inclusions-binary-*"))" \
      $ARGS \
      --libraries ${REF_DIR} ${SEARCH_ROOT} 
      
  elif [ "$MODE" == "source-only" ] ; then

    $REF_DIR/generate-license-and-notice.sh \
      -o $OUT \
      --license $PARTS_DIR/license-top \
      --license $PARTS_DIR/license-deps-source-dist \
      --notice $PARTS_DIR/notice-top-source-dist --notice-compute-with-flags "
        -DextrasFiles=$(prefix_and_join_array "" ":" "" $(find -L $SEARCH_ROOT -name "license-inclusions-source-*"))
        -DonlyExtras=true" \
      $ARGS \
      --libraries ${REF_DIR} ${SEARCH_ROOT}

  else
    echo FAILED - unknown mode $MODE
    exit 1
  fi
  echo ""
  
  popd > /dev/null
}

make_for_source() {
    make_for "$1" "$2" "$3" source-then-additional-binary "$4" "$5"
    # DEPENDENCIES 
    mv $OUT/NOTICE $OUT/DEPENDENCIES
    echo "" >> $OUT/DEPENDENCIES
    cat $OUT/LICENSE >> $OUT/DEPENDENCIES
    rm $OUT/LICENSE
    
    make_for "$1" "$2" "$3" source-only "$4" "$5"
}

# build licenses for all the projects

if [ "$LOAD_ONLY" == "true" ] ; then 
  echo loaded license generation libraries

else


# include deps in files pulled in to Go CLI binary builds
make_for $ROOT_DIR/brooklyn-client/cli/ . release/license/files binary
make_for_source $ROOT_DIR/brooklyn-client/cli/ . .

# Server CLI has embedded JS; gets custom files in sub-project root, also included in JAR
make_for_source $ROOT_DIR/brooklyn-server/server-cli/ . .

# UI gets files at root
make_for_source $ROOT_DIR/brooklyn-ui/ features .
# for UI also do for each standalone module
for x in $(ls $ROOT_DIR/brooklyn-ui/ui-modules/*/package.json) ; do
  make_for_source ${x%package.json} . .
  # and in modules which make a WAR/JAR files we embed binaries
  if [ -d ${x%package.json}/src/main/webapp ] ; then make_for ${x%package.json} . src/main/webapp/WEB-INF/classes/META-INF/ binary ; fi
done

# main projects have their binaries included at root
make_for_source $ROOT_DIR/brooklyn-server/ karaf/features .
make_for_source $ROOT_DIR/brooklyn-client/ java .
make_for_source $ROOT_DIR/brooklyn-library karaf/features .
make_for_source $ROOT_DIR/brooklyn-dist karaf/features .

 
# brooklyn-docs skipped
# the docs don't make a build and don't include embedded code so no special license there

# for the root source do as for dist but get the additional includes from all brooklyn projects
make_for_source $ROOT_DIR/brooklyn-dist karaf/features .. $ROOT_DIR

# and the binary dist is the same, stored in a couple places for inclusion in the binary builds
make_for $ROOT_DIR/brooklyn-dist karaf/features dist/src/main/license/files/ binary $ROOT_DIR
cp $OUT/{NOTICE,LICENSE} $PROJ/../features/src/main/resources/resources/
cp $OUT/{NOTICE,LICENSE} $PROJ/../apache-brooklyn/src/main/resources/

fi
