
### Brooklyn Karaf Distribution Docker Image

The instructions in this directory will build a Docker image of the `apache-brooklyn` Karaf distribution. 
This is an optional step in the build of Apache Brooklyn, enabled as a profile:

```bash
mvn clean install -Pdocker 
```

Docker should be installed and running when doing such a build.

The image can then be run as usual with Docker. For example create a folder `my-brooklyn-config` which 
contains an `etc` directory containing your configuration for Brooklyn. Then Brooklyn can be run as:
 

```bash
docker run --name brooklyn -d -p8081:8081 -p8443:8443 -v ${HOME}/my-brooklyn-config/etc:/brooklyn/etc apache/brooklyn:1.0.0-SNAPSHOT
```