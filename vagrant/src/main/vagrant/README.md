
# [![**Brooklyn**](https://brooklyn.apache.org/style/img/apache-brooklyn-logo-244px-wide.png)](http://brooklyn.apache.org/)

### Using Vagrant with Brooklyn -SNAPSHOT builds

##### Install a community-managed version from Maven
1. No action is required other than setting the  `BROOKLYN_VERSION:` environment variable in `servers.yaml` to a `-SNAPSHOT` version. For example:

   ```
   env:
     BROOKLYN_VERSION: 1.0.0-M1
   ```

2. You may proceed to use the `Vagrantfile` as normal; `vagrant up`, `vagrant destroy` etc.

##### Install a locally built RPM package

1. Set the `BROOKLYN_VERSION:` environment variable in `servers.yaml` to your current `-SNAPSHOT` version. For example:

   ```
   env:
     BROOKLYN_VERSION: 1.0.0-M1
   ```

2. Set the `INSTALL_FROM_LOCAL_DIST:` environment variable in `servers.yaml` to `true`. For example:

   ```
   env:
     INSTALL_FROM_LOCAL_DIST: true
   ```


3. Copy your locally built `apache-brooklyn-<version>.noarch.rpm` archive to the same directory as the Vagrantfile (this directory is mounted in the Vagrant VM at `/vagrant/`).

   For example to copy a locally built `0.12.0-SNAPSHOT` dist:

   ```
   cp ~/.m2/repository/org/apache/brooklyn/rpm-packaging/0.12.0-SNAPSHOT/rpm-packaging-0.12.0-SNAPSHOT-noarch.rpm ./apache-brooklyn-0.12.0-SNAPSHOT.noarch.rpm
   ```

4. You may proceed to use the `Vagrantfile` as normal; `vagrant up`, `vagrant destroy` etc.
