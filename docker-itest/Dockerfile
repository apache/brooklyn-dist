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

FROM maven:3.3-jdk-8
MAINTAINER Svetoslav Neykov "svetoslav.neykov@cloudsoft.io"

# For Alpine:
# FROM maven:3.3.9-jdk-8-alpine
# RUN apk add --update --no-cache bash netcat-openbsd sudo wget openssh
# RUN ssh-keygen -A
# This is missing knife - adding it would grow the image size considerably
# making it on par with the full debian image. Also some tests fail
# because of differences in the accepted arguments of the busybox provided tools.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends net-tools ssh sudo wget chef && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir /etc/skel/.m2 && \
    echo "<settings xmlns='http://maven.apache.org/SETTINGS/1.0.0'>" > /etc/skel/.m2/settings.xml && \
    echo "  <localRepository>/maven-repo</localRepository>" >> /etc/skel/.m2/settings.xml && \
    echo "</settings>" >> /etc/skel/.m2/settings.xml && \
    : The following are integration tests requirements && \
    echo "127.0.0.1 localhost1 localhost2 localhost3 localhost4" >> /etc/hosts && \
    mkdir /etc/skel/.brooklyn && \
    cd /etc/skel/.brooklyn && \
    wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz && \
    gunzip GeoLite2-City.mmdb.gz && \
    echo "brooklyn.location.named.localhost-passphrase=localhost" >> brooklyn.properties && \
    echo "brooklyn.location.named.localhost-passphrase.privateKeyFile=~/.ssh/id_rsa_with_passphrase" >> brooklyn.properties && \
    echo "brooklyn.location.named.localhost-passphrase.privateKeyPassphrase=mypassphrase" >> brooklyn.properties && \
    chmod 600 brooklyn.properties

# Add the brooklyn user at runtime so that we can set its USER_ID same as the user that's calling "docker run"
# We need them the same so that the mounted /build volume is accessible from inside the container.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

VOLUME /build
VOLUME /maven-repo

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mvn -B clean install -PIntegration"]
