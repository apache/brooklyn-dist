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

BROOKLYN_VERSION=0.12.0

default: all

clean:
	rm -rf target/

prep: clean
	mkdir -p target/files/
	cp -a ../dist/target/brooklyn-dist/brooklyn/* target/files
	cp -a target/files/bin/brooklyn-client-cli/linux.386/br target/files/bin/
	cp -a brooklyn-docker-start target/files/bin/

image-only:
	docker build -t brooklyncentral/brooklyn:$(BROOKLYN_VERSION) .

image-debug: prep
        # image based on ubuntu (instead of alpine) with more tools installed and better debug output
	docker build -t brooklyncentral/brooklyn:${BROOKLYN_VERSION}-debug -f Dockerfile-debug-ubuntu .

all: prep image-only


# illustrations, useful for copy-pasting

run:
        # BROOKLYN_VERSION_BELOW
	docker run -d -p 8081:8081 brooklyncentral/brooklyn:${BROOKLYN_VERSION} --password S3CR3T > /tmp/brooklyn_container
	docker logs -f `cat /tmp/brooklyn_container`

run-shell:
	docker run -ti --entrypoint /bin/bash brooklyncentral/brooklyn:$(BROOKLYN_VERSION)


# an example pre-installing blueprints and even taking a location as argument to quick launch

example-image-hyperledger: prep
	docker build -t brooklyncentral/brooklyn-hyperledger \
	  --build-arg install_boms="https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/docker.bom \
	    https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/catalog.bom" \
          --build-arg application=hyperledger-fabric-single-cluster-application \
	  .

example-run-hyperledger:
	# add   id:cred@cloud   as an argument to launch the blueprint in that cloud
	docker run -p 8081:8081 brooklyncentral/brooklyn-hyperledger --password S3CR3T

example-image-kubernetes: prep
	docker build -t brooklyncentral/brooklyn-kubernetes \
	  --build-arg install_boms="classpath://swarm/catalog.bom classpath://kubernetes/catalog.bom" \
	  --build-arg dropins_jars="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=io.brooklyn.etcd&a=brooklyn-etcd&v=2.3.0-SNAPSHOT \
	    https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=io.brooklyn.clocker&a=clocker-common&v=2.1.0-SNAPSHOT \
	    https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=io.brooklyn.clocker&a=clocker-swarm&v=2.1.0-SNAPSHOT \
	    https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=io.brooklyn.clocker&a=clocker-kubernetes&v=2.1.0-SNAPSHOT" \
         --build-arg application=kubernetes-cluster-template \
         .

