
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
	docker build -t brooklyncentral/brooklyn:${BROOKLYN_VERSION} --build-arg debug=true .

all: prep image-only

# copy this if you want to pass arguments
run:
        # BROOKLYN_VERSION_BELOW
	docker run -p 8081:8081 brooklyncentral/brooklyn:0.10.0-SNAPSHOT

run-shell:
	docker run -ti --entrypoint /bin/bash brooklyncentral/brooklyn:$(BROOKLYN_VERSION)


# an example

example-image-hyperledger: prep
	docker build -t brooklyncentral/brooklyn-hyperledger \
	  --build-arg install_bom="https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/docker.bom https://raw.githubusercontent.com/cloudsoft/brooklyn-hyperledger/master/catalog.bom" \
          --build-arg application=hyperledger-fabric-multi-cluster-application \
	  .

example-run-hyperledger:
	docker run -p 8081:8081 brooklyncentral/brooklyn-hyperledger


