General Scripts
===============

This folder contains a number of items that can assist developers of the project.

In general see comments at the start of each file and/or `--help` output when running it.

You can install the `*.sh` files as commands (without the `.sh` suffix linked to these) to your `bin` dir with:

    for x in *.sh ; do sudo ln -s `pwd`/$x /usr/local/bin/${x%.sh}; done


