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


FROM ubuntu:latest
MAINTAINER Alex Heneveld "alex@cloudsoft.io"

RUN apt-get update

# pre-reqs for Brooklyn
RUN apt-get install -y default-jre

# and for the script
RUN apt-get install -y ssh

ARG debug

# admin tools (optional)
RUN if [ -n "${debug}" ] ; then apt-get install -y vim ; fi
RUN if [ -n "${debug}" ] ; then apt-get install -y zip tar less curl ; fi
RUN if [ -n "${debug}" ] ; then apt-get install -y sudo ; fi

RUN adduser brooklyn
WORKDIR /home/brooklyn

COPY target/files/ .
RUN cp ./bin/br /usr/bin/br
RUN chown -R brooklyn:brooklyn .

USER brooklyn

# remove option not relevant for java v8
RUN sed -i.bk "s/ -XX:MaxPermSize=256m//" bin/brooklyn

ARG application
ARG install_bom

RUN if [ -n "${debug}" ] ; then echo debug=true >> brooklyn-docker-start.opts ; fi
RUN if [ -n "${application}" ] ; then echo application=${application} >> brooklyn-docker-start.opts ; fi

RUN if [ -n "${install_bom}" ] ; then \
  echo "brooklyn.catalog:" > conf/brooklyn/default.catalog.bom ; \
  echo "  items:" >> conf/brooklyn/default.catalog.bom ; \
  for x in ${install_bom} ; do \
    echo Installing $x to catalog ; \
    echo "  - "$x >> conf/brooklyn/default.catalog.bom ; \
  done \
fi

ENTRYPOINT ["bin/brooklyn-docker-start"]
CMD []

