#!/usr/bin/env bash

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

BROOKLYN_VERSION=""
INSTALL_FROM_LOCAL_DIST="false"
TMP_ARCHIVE_NAME=apache-brooklyn.rpm

do_help() {
  echo "./install.sh -v <Brooklyn Version> [-l <install from local file: true|false>]"
  exit 1
}

while getopts ":hv:l:" opt; do
    case "$opt" in
    v)  BROOKLYN_VERSION=$OPTARG ;;
        # using a true/false argopt rather than just flag to allow easier integration with servers.yaml config
    l)  INSTALL_FROM_LOCAL_DIST=$OPTARG ;;
    h)  do_help;;
    esac
done

# Exit if any step fails
set -e

if [ "x${BROOKLYN_VERSION}" == "x" ]; then
  echo "Error: you must supply a Brooklyn version [-v]"
  do_help
fi

if [ ! "${INSTALL_FROM_LOCAL_DIST}" == "true" ]; then
  if [ ! -z "${BROOKLYN_VERSION##*-SNAPSHOT}" ] ; then
    # url for official release versions
    BROOKLYN_URL="https://www.apache.org/dyn/closer.lua?action=download&filename=brooklyn/apache-brooklyn-${BROOKLYN_VERSION}/apache-brooklyn-${BROOKLYN_VERSION}.noarch.rpm"
  else
    # url for community-managed snapshots
    BROOKLYN_URL="https://repository.apache.org/service/local/artifact/maven/redirect?r=snapshots&g=org.apache.brooklyn&a=rpm-packaging&v=${BROOKLYN_VERSION}&c=noarch&e=rpm"
  fi
else
  echo "Installing from a local -dist archive [ /vagrant/apache-brooklyn-${BROOKLYN_VERSION}.noarch.rpm]"
  # url to install from mounted /vagrant dir
  BROOKLYN_URL="file:///vagrant/apache-brooklyn-${BROOKLYN_VERSION}.noarch.rpm"

  # ensure local file exists
  if [ ! -f /vagrant/apache-brooklyn-${BROOKLYN_VERSION}.noarch.rpm ]; then
    echo "Error: file not found /vagrant/apache-brooklyn-${BROOKLYN_VERSION}.noarch.rpm"
    exit 1
  fi
fi

echo "Downloading Brooklyn release archive"
curl --fail --silent --show-error --location --output ${TMP_ARCHIVE_NAME} "${BROOKLYN_URL}"

echo "Restarting Syslog"
sudo systemctl restart rsyslog

echo "Updating Yum"
sudo yum -y update

echo "Install Java"
sudo yum install -y java-1.8.0-openjdk-headless

echo "Install Apache Brooklyn version ${BROOKLYN_VERSION} from [${BROOKLYN_URL}]"
sudo yum -y install ${TMP_ARCHIVE_NAME}

echo "Configure catalog"
sudo cp /vagrant/files/vagrant-catalog.bom /opt/brooklyn/catalog/vagrant-catalog.bom
sudo chown brooklyn:brooklyn /opt/brooklyn/catalog/vagrant-catalog.bom
sudo chmod 740 /opt/brooklyn/catalog/vagrant-catalog.bom
echo '  - file:catalog/vagrant-catalog.bom' | sudo tee -a /etc/brooklyn/default.catalog.bom

echo "Starting Apache Brooklyn..."
sudo systemctl start brooklyn

echo "Waiting for Apache Brooklyn to start..."
sleep 10

while ! (sudo grep "Brooklyn initialisation (part two) complete" /var/log/brooklyn/brooklyn.debug.log) > /dev/null ; do
  sleep 10
  echo ".... waiting for Apache Brooklyn to start at `date`"
done

echo "============================================================================================="
echo "============            ____  ____   ____    __  __ __    ___                              =="
echo "============           /    ||    \ /    |  /  ]|  |  |  /  _]                             =="
echo "============          |  o  ||  o  )  o  | /  / |  |  | /  [_                              =="
echo "============          |     ||   _/|     |/  /  |  _  ||    _]                             =="
echo "============          |  _  ||  |  |  _  /   \_ |  |  ||   [_                              =="
echo "============          |  |  ||  |  |  |  \     ||  |  ||     |                             =="
echo "============          |__|__||__|  |__|__|\____||__|__||_____|                             =="
echo "============                                                                               =="
echo "============       ____   ____   ___    ___   __  _  _      __ __  ____                    =="
echo "============      |    \ |    \ /   \  /   \ |  |/ ]| |    |  |  ||    \                   =="
echo "============      |  o  )|  D  )     ||     ||  ' / | |    |  |  ||  _  |                  =="
echo "============      |     ||    /|  O  ||  O  ||    \ | |___ |  ~  ||  |  |                  =="
echo "============      |  O  ||    \|     ||     ||     \|     ||___, ||  |  |                  =="
echo "============      |     ||  .  \     ||     ||  .  ||     ||     ||  |  |                  =="
echo "============      |_____||__|\_|\___/  \___/ |__|\_||_____||____/ |__|__|                  =="
echo "============                                                                               =="
echo "============        _____ ______   ____  ____  ______    ___  ___    __                    =="
echo "============       / ___/|      | /    ||    \|      |  /  _]|   \  |  |                   =="
echo "============      (   \_ |      ||  o  ||  D  )      | /  [_ |    \ |  |                   =="
echo "============       \__  ||_|  |_||     ||    /|_|  |_||    _]|  D  ||__|                   =="
echo "============       /  \ |  |  |  |  _  ||    \  |  |  |   [_ |     | __                    =="
echo "============       \    |  |  |  |  |  ||  .  \ |  |  |     ||     ||  |                   =="
echo "============        \___|  |__|  |__|__||__|\_| |__|  |_____||_____||__|                   =="
echo "============                                                                               =="
echo "============================================================================================="