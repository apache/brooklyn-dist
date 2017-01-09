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
if [ "$(id -u)" = "0" ]; then
  echo "Setting up system"
  echo "brooklyn ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers.d/brooklyn
  chmod 0440 /etc/sudoers.d/brooklyn
  GROUP_ID=${DOCKER_GROUP_ID:-1000}
  USER_ID=${DOCKER_USER_ID:-1000}
  #(alpine): addgroup -g $GROUP_ID brooklyn
  #(alpine): adduser -g "brooklyn" -s /bin/bash -G brooklyn -u $USER_ID -D brooklyn 
  groupadd -g $GROUP_ID brooklyn
  echo "Creating user"
  useradd --shell /bin/bash -u $USER_ID -o -c "" -m -k /etc/skel -g brooklyn brooklyn 
  chown brooklyn:brooklyn /home/brooklyn
  sudo service ssh start
  exec sudo -H -u brooklyn -i /usr/local/bin/entrypoint.sh $@
else
  echo "Setting up Brooklyn"
  # Integration tests requirements
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  ssh-keygen -t rsa -N "mypassphrase" -f ~/.ssh/id_rsa_with_passphrase
  cat ~/.ssh/id_rsa_with_passphrase.pub >> ~/.ssh/authorized_keys

  cd /build
  echo "Available entropy in container: $(cat /proc/sys/kernel/random/entropy_avail)"
  exec $@
fi
