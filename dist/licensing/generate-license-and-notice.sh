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

Usage:  generate-license-and-notice.sh [-o <output-dir>] [-s <suffix>] 
          [ --license <license-file>]+
          [ [--notice <header-file>]
            [--notice-compute-with-flags <flags>]* ]+
          [--libraries <search-dir> [<seach-dir>]+]
          [--keep-metadata-file <filename>]

Generates LICENSE and NOTICE files based on dependencies.

Required parameters:

* -o <output-dir> is where the files are written, defaulting to current working directory

* -s <suffix> specifies a suffix to add to the names of the files generated

* --license <license-file>  causes the given license file to be written to the LICENSE file
  prior to licenses inferred from notices; the last entry is only written if there are licenses
  in the NOTICE file

* --notice <header-file>  causes the contents of <header-file> to be written to the NOTICE file

* --notice-compute-with-flags <flags> passes the given flags to the maven license-audit-plugin 
  to generate the YAML data for the NOTICE and LICENSE files

* --libraries <search-dir> [<search-dir>]+  supplies one or more directories to scan for 
  reference files, of the form license-metadata-*.yaml, containing a list of items each 
  with an id and various other metadata fields; these items are used to populate the 
  section reports described above by passing to the maven license-audit-plugin, or to
  look for a directories called license-text which are searched for the names of licenses
  as declared in the generated NOTICE file

The generated LICENSE file contains the indicated license sections followed by other licenses 
referenced by the dependencies.

The NOTICE file contains the output as per --notice and --notice-compute-with-flags in the order specified.
Typical usage is to have one root --notice then one or more -notice ... --notice-compute-with-flags ... blocks.

EOF
}

OUTPUT_DIR=.
SUFFIX=""
LICENSES=()
NOTICE_SECTION_TYPE=()
NOTICE_SECTION_ARG=()
LIBRARIES=()

while [ ! -z "$*" ] ; do

  if [ "$1" == "--help" ]; then usage ; exit 0; fi

  if [ "$1" == "-o" ]; then OUTPUT_DIR=$2 ; shift 2 ; continue ; fi
  if [ "$1" == "-s" ]; then SUFFIX=$2 ; shift 2 ; continue ; fi
  if [ "$1" == "--license" ]; then LICENSES[${#LICENSES[*]}]=$2 ; shift 2 ; continue ; fi

  if [[ "$1" == "--notice" || "$1" == "--notice-compute-with-flags" ]]; then
    I=${#NOTICE_SECTION_TYPE[*]}
    NOTICE_SECTION_TYPE[$I]=${1:2}
    NOTICE_SECTION_ARG[$I]=$2
    shift 2
    continue
  fi

  if [ "$1" == "--libraries" ] ; then
    shift
    LIBRARIES=(${LIBRARIES[@]} $@)
    shift $#
    continue
  fi

  if [ "$1" == "--keep-metadata-file" ] ; then
    shift
    KEEP_METADATA_FILE=$1
    shift
    continue
  fi

  usage
  echo Unexpected argument: $1
  exit 1 

done

NOTICE_FILE=${OUTPUT_DIR}/NOTICE${SUFFIX}
LICENSE_FILE=${OUTPUT_DIR}/LICENSE${SUFFIX}

echo Writing to $NOTICE_FILE and $LICENSE_FILE...

error() {
  echo "*** This file is incomplete. ***" >> $NOTICE_FILE
  echo "*** This file is incomplete. ***" >> $LICENSE_FILE
  echo ""
  echo "" >&2
  echo "ERROR - "$2 >&2
  echo "" >&2
  exit $1
}

onTrappedError() {
  error 9 "Execution aborted"
}

trap onTrappedError ERR

rm -f $NOTICE_FILE $LICENSE_FILE

if [ "${#NOTICE_SECTION_TYPE[@]}" == "0" ] ; then echo "\nNo sections included for NOTICE. No point in proceeing." ; exit 1 ; fi


TEMP_METADATA_FILE=`pwd -P`/temp.license-metadata.yaml
TEMP_NOTICE_DATA_FILE=`pwd -P`/temp.license-notice-data.yaml
TEMP_LICENSES_=`pwd -P`/temp.license-list-
TEMP_MVN_OUT=`pwd -P`/temp.license-maven-output.log

echo > $TEMP_METADATA_FILE
if [ ! -z "$LIBRARIES" ] ; then
  echo Using metadata libraries from "${LIBRARIES[@]}": $(find -L "${LIBRARIES[@]}" -name "license-metadata-*")
  # sort by filename first, then by path, with later ones alpha being the ones that are ultimately used
  for x in $(find -L "${LIBRARIES[@]}" -name "license-metadata-*" | sed 's/\(.*\/\)\(.*\)/\2 --- \1\2/' | sort | sed 's/.* --- //') ; do
    cat $x >> $TEMP_METADATA_FILE
  done
fi

process_dependencies() {
  mvn -X org.heneveld.maven:license-audit-maven-plugin:notices \
        -DlicensesPreferred=Apache-2.0,Apache,EPL-1.0,BSD-2-Clause,BSD-3-Clause,CDDL-1.1,CDDL-1.0,CDDL \
        -DoverridesFile=$TEMP_METADATA_FILE \
        -DoutputYaml=true \
        -DoutputFile=$TEMP_NOTICE_DATA_FILE \
        $@ > $TEMP_MVN_OUT || (cat $TEMP_MVN_OUT && error 2 "mvn error")
  sed "s/^/  /" < $TEMP_NOTICE_DATA_FILE >> $NOTICE_FILE
  
  if [ ! -s "$TEMP_NOTICE_DATA_FILE" ] ; then
    echo "  # No such dependencies" >> $NOTICE_FILE
    echo "" >> $NOTICE_FILE
  fi 
}

for ((I=0; I<${#NOTICE_SECTION_TYPE[@]}; I++)); do
  echo Adding ${NOTICE_SECTION_TYPE[$I]} section ${NOTICE_SECTION_ARG[$I]} to $NOTICE_FILE

  if [ "${NOTICE_SECTION_TYPE[$I]}" == "notice" ] ; then
    cat ${NOTICE_SECTION_ARG[$I]} >> $NOTICE_FILE
    continue
  fi

  if [ "${NOTICE_SECTION_TYPE[$I]}" == "notice-compute-with-flags" ] ; then
    process_dependencies "${NOTICE_SECTION_ARG[$I]}"
    continue
  fi

  error "Unknown notice section type ${NOTICE_SECTION_TYPE[$I]}"

done

for (( I=0; I<${#LICENSES[@]}-1; I++ )) ; do
  echo Adding ${LICENSES[$I]} to $LICENSE_FILE
  cat ${LICENSES[$I]} >> $LICENSE_FILE
done

grep "License name:" $NOTICE_FILE | sed "s/.*://" > ${TEMP_LICENSES_}1 
cat ${TEMP_LICENSES_}1 | while read x ; do echo $x ; done | sort | uniq > ${TEMP_LICENSES_}2

MISSING=()

if [ -s ${TEMP_LICENSES_}2 ] ; then
  echo Adding ${LICENSES[$I]} to $LICENSE_FILE and `cat ${TEMP_LICENSES_}2 | wc -l` licenses:`cat ${TEMP_LICENSES_}2 | sed 's/^/ /' | paste -sd ';' -`
  cat ${LICENSES[${#LICENSES[@]}-1]} >> $LICENSE_FILE
  LICENSE_TEXT_PATHS=$(find -L ${LIBRARIES[@]} -name license-text) 

  while read x ; do
  
    echo "  "$x": |" >> $LICENSE_FILE
    
    unset FOUND
    for lp in ${LICENSE_TEXT_PATHS} ; do
      if [ -f "$lp/$x" ] ; then
       if [ -z "$FOUND" ]; then
        cat "$lp/$x" | sed "s/^/    /" >> $LICENSE_FILE
        echo "" >> $LICENSE_FILE
        FOUND=true
       fi
      fi
    done
    if [ -z "$FOUND" ]; then
      echo Missing license "$x".
      echo "    MISSING LICENSE: "$x >> $LICENSE_FILE
      echo "" >> $LICENSE_FILE
      MISSING=("${MISSING[@]}" "$x")
    fi
  done < ${TEMP_LICENSES_}2
fi

if [ ! -z "$MISSING" ] ; then
  echo ""
  echo License files missing in license-text/ in ${LIBRARIES[@]}
  for x in "${MISSING[@]}" ; do
    grep -A1 ": $x\$" $NOTICE_FILE | head -2
  done    
  error 3 "Missing license text files" 
fi

cp $NOTICE_FILE $NOTICE_FILE.tmp
grep -v "License URL:" $NOTICE_FILE.tmp > $NOTICE_FILE

if [ ! -z "$KEEP_METADATA_FILE" ] ; then
  cp $TEMP_METADATA_FILE $KEEP_METADATA_FILE
fi

rm -f $NOTICE_FILE.tmp $TEMP_METADATA_FILE $TEMP_NOTICE_DATA_FILE $TEMP_MVN_OUT ${TEMP_LICENSES_}*

exit 0
