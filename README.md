
# [![**Brooklyn**](https://brooklyn.apache.org/style/img/apache-brooklyn-logo-244px-wide.png)](http://brooklyn.apache.org/)

### Distribution Sub-Project for Apache Brooklyn

This repo contains modules for creating the distributable binary
combining the `server`, the `ui`, and other elements in other Brooklyn repos.

### Building the project

2 methods are available to build this project: within a docker container or directly with maven.

#### Using docker

The project comes with a `Dockerfile` that contains everything you need to build this project.
First, build the docker image:

```bash
docker build -t brooklyn:dist .
```

Then run the build:

```bash
docker run -i --rm --name brooklyn-dist -v ${HOME}/.m2:/root/.m2 -v ${PWD}:/usr/build -w /usr/build brooklyn:dist mvn clean install
```

### Using maven

Simply run:

```bash
mvn clean install
```