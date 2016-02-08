
# [![**Brooklyn**](https://brooklyn.apache.org/style/img/apache-brooklyn-logo-244px-wide.png)](http://brooklyn.apache.org/)

### Apache Brooklyn Vagrant Sub-Project.

This repo contains the files to generate a preconfigured Vagrant environment for use with the [Getting Started Guide](http://brooklyn.apache.org/v/latest/start/index.html).

#### Building the Vagrant archive

This project is built as part of the main Brooklyn project but can also be built locally with:
```
mvn clean install
```

The resulting archive artifact can be found in:
```
./target/brooklyn-vagrant-<BROOKLYN_VERSION>-dist.zip
```
Extract and cd into this archive at which point you can follow the [Getting Started Guide](http://brooklyn.apache.org/v/latest/start/index.html) steps.

#### Distributing the Vagrant archive release

This artifact will be distributed via the ASF mirrors as part of the release process.

#### Additional information

Some additional information is provided in the [README.md](src/main/vagrant/README.md) distributed in the Vagrant archive.
