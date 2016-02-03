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

# runs mvn fast in several dirs; run with `-h` for more info


export DIRS=""
export ARGS="-o clean install -DskipTests"
if [[ -z $1 || $1 = "-h" || $1 == "--help" ]] ; then
  echo
  echo "MVNF: a simple script for building multiple maven directories"
  echo
  echo "usage:  mvnf [ -x \"install -Dxxx\" ] dir1 [ dir2 [ ... ]]"
  echo
  echo "This will do a maven build in each directory specified, in order, "
  echo "giving arguments '-o clean install -DskipTests' to mvn by default "
  echo "or other arguments if supplied in the word following -x at start. "
  echo "The script aborts if any build fails, giving the last return code "
  echo "code, and returning to the directory where it was invoked."
  echo
  echo "eg: \`mvnf ../other . && ./target/dist/run.sh\`"
  echo "    will build other, then build ., then run a just-build script "
  echo "    if all went well (but if it fails you'll see that too)"
  echo
  if [ -z $1 ] ; then exit 1 ; fi
  exit 0
fi
if [ $1 = "-x" ] ; then
  shift
  export ARGS=$1
  shift
fi
echo "MVNF: running \`mvn $ARGS\` on: $@"
for x in $@
do
  if [ ! -d $x ] ; then
    export RETVAL=1
    echo "MVNF: no such directory $x"
    break
  fi
  if [ ! -f $x/pom.xml ] ; then
    export RETVAL=1
    echo "MVNF: no pom available in $x"
    break
  fi
  pushd $x > /dev/null
  export DIR=`basename \`pwd\``
  echo "MVNF: building $DIR (${x})"
  mvn $ARGS
  export RETVAL=$?
  export DIRS="${DIRS}${DIR} "
  echo
  popd > /dev/null
  if [ $RETVAL != 0 ] ; then 
    echo "MVNF: mvn failed in directory $DIR (${x})"
    break
  fi
done
if [ $RETVAL = 0 ] ; then
  echo MVNF: successfully built $DIRS
fi
test ${RETVAL} = 0
