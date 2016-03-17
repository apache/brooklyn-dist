#!/bin/bash
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

set -e
set -x

# Do the basics
git clone http://github.com/apache/brooklyn/
cd brooklyn
git submodule init
git submodule update --remote --merge --recursive

# Replace the origin - was GitHub, needs to be Apache canonical
git remote add apache-git https://git-wip-us.apache.org/repos/asf/brooklyn
git submodule foreach 'git remote add apache-git https://git-wip-us.apache.org/repos/asf/${name}'
git fetch apache-git
git submodule foreach 'git fetch apache-git'
git checkout master
git submodule foreach 'git checkout master'
git branch --set-upstream-to apache-git/master master
git submodule foreach 'git branch --set-upstream-to apache-git/master master'
git reset --hard apache-git/master
git submodule foreach 'git reset --hard apache-git/master'
git remote remove origin
git submodule foreach 'git remote remove origin'

# Final check we are up to date
git pull
git submodule update --remote --merge --recursive

# And also the location for publishing RC artifacts
svn co --depth=immediates https://dist.apache.org/repos/dist/dev/brooklyn ~/apache-dist-dev-brooklyn
echo "export APACHE_DIST_SVN_DIR=$HOME/apache-dist-dev-brooklyn" >> ~/.profile
