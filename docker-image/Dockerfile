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
LABEL maintainer="Brooklyn Team :: https://brooklyn.apache.org/"
EXPOSE 8081 8443

ARG DIST_TAR_GZ
COPY ${DIST_TAR_GZ} brooklyn.tar.gz
ENV EXTRA_JAVA_OPTS="-XX:SoftRefLRUPolicyMSPerMB=1 -Djava.security.egd=file:/dev/./urandom"

RUN apk --no-cache add bash ; \
    mkdir brooklyn ; \
    tar xzf brooklyn.tar.gz -C /brooklyn --strip-components 1 ;

ENTRYPOINT ["/brooklyn/bin/karaf"]
CMD ["server"]
