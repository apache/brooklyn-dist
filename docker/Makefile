
BROOKLYN_VERSION=0.10.0-SNAPSHOT

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
	docker run -d -p 8081:8081 brooklyncentral/brooklyn:0.10.0-SNAPSHOT --password S3CR3T > /tmp/brooklyn_container
	docker logs -f `cat /tmp/brooklyn_container`

run-shell:
	docker run -ti --entrypoint /bin/bash brooklyncentral/brooklyn:$(BROOKLYN_VERSION)


# an example pre-installing blueprints and even taking a location as argument to quick launch

example-image-hyperledger: prep
	docker build -t brooklyncentral/brooklyn-hyperledger \
	  --build-arg install_bom="https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/docker.bom https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/catalog.bom" \
          --build-arg application=hyperledger-fabric-single-cluster-application \
	  .

example-run-hyperledger:
	# add   id:cred@cloud   as an argument to launch the blueprint in that cloud
	docker run -p 8081:8081 brooklyncentral/brooklyn-hyperledger --password S3CR3T


