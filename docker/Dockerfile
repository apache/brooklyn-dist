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


FROM openjdk:8-jre-alpine
MAINTAINER Alex Heneveld "alex@cloudsoft.io"

RUN apk add --update --no-cache bash openssh wget
RUN adduser -D brooklyn
WORKDIR /home/brooklyn

# now install software brooklyn
COPY target/files/ .
RUN \
  # install br for global use \
  cp ./bin/br /usr/bin/br ; \
  # and fix perms (irritating that docker won't do this) \
  chown -R brooklyn:brooklyn .

USER brooklyn

# handle customisation, including passing args through to the container script and installing boms
ARG application
ARG install_boms
ARG dropins_jars
RUN \
  if [ -n "${debug}" ] ; then echo debug=true >> brooklyn-docker-start.opts ; fi ; \
  if [ -n "${application}" ] ; then echo application=${application} >> brooklyn-docker-start.opts ; fi ; \
  if [ -n "${install_boms}" ] ; then \
    echo "brooklyn.catalog:" > conf/brooklyn/default.catalog.bom ; \
    echo "  items:" >> conf/brooklyn/default.catalog.bom ; \
    for x in ${install_boms} ; do \
      echo Installing $x to catalog ; \
      echo "  - "$x >> conf/brooklyn/default.catalog.bom ; \
    done ; \
  fi ; \
  if [ -n "${dropins_jars}" ] ; then \
    cd lib/dropins/ ; \
    for x in ${dropins_jars} ; do \
      echo Download $x to lib/dropins ; \
      wget -q --trust-server-names $x ; \
    done ; \
  fi

# and start
EXPOSE 8081
ENTRYPOINT ["bin/brooklyn-docker-start"]
CMD []

