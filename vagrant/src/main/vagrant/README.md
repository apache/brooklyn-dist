
# [![**Brooklyn**](https://brooklyn.apache.org/style/img/apache-brooklyn-logo-244px-wide.png)](http://brooklyn.apache.org/)

### Using Vagrant with Brooklyn -SNAPSHOT builds

##### Install a community-managed version from Maven
1. No action is required other than setting the  `BROOKLYN_VERSION:` environment variable in `servers.yaml` to a `-SNAPSHOT` version. For example:

   ```
   env:
     BROOKLYN_VERSION: 0.12.0
   ```

2. You may proceed to use the `Vagrantfile` as normal; `vagrant up`, `vagrant destroy` etc.

##### Install a locally built `-dist.tar.gz`

1. Set the `BROOKLYN_VERSION:` environment variable in `servers.yaml` to your current `-SNAPSHOT` version. For example:

   ```
   env:
     BROOKLYN_VERSION: 0.12.0
   ```

2. Set the `INSTALL_FROM_LOCAL_DIST:` environment variable in `servers.yaml` to `true`. For example:

   ```
   env:
     INSTALL_FROM_LOCAL_DIST: true
   ```


3. Copy your locally built `apache-brooklyn-<version>.tar.gz` archive to the same directory as the Vagrantfile (this directory is mounted in the Vagrant VM at `/vagrant/`).

   For example to copy a locally built `0.12.0-SNAPSHOT` dist:

   ```
   cp ~/.m2/repository/org/apache/brooklyn/apache-brooklyn/0.12.0-SNAPSHOT/apache-brooklyn-0.12.0-SNAPSHOT.tar.gz .
   ```

4. You may proceed to use the `Vagrantfile` as normal; `vagrant up`, `vagrant destroy` etc.
