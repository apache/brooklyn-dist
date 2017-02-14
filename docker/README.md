
This folder is not part of the build but exists to facilitate making Docker images containing Brooklyn.

To use, with `docker` tools installed, run `make all` after the Brooklyn `dist` has been built.
Then do `make run` to see the options (or look in [brooklyn-docker-start]()).

When building, you can use:

* `--build-arg debug=true` to install extra tools on the VM and show debug output from our script when booting the container
* `--build-arg application=my-app` to create a container which boots `my-app` by default
* `--build-arg install_boms="http://path/to/file.bom http://path/to/another.bom"` to replace the default catalog with one or more BOM files (useful with `application` above)
* `--build-arg dropins_jars="http://path/to/file.jar http://path/to/another.jar"` to add JARs in the dropins dir (useful with `application` and `install_boms` above)

See examples in the `Makefile`.

