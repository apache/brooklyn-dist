#!/bin/bash

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

getent group brooklyn || groupadd -r brooklyn
getent passwd brooklyn || useradd -r -g brooklyn -d /opt/brooklyn -s /sbin/nologin brooklyn
# Remove the symbolic link "/opt/brooklyn" if exists (means that we are upgrading brooklyn)
BROOKLYN_ROOT=/opt/brooklyn
if [[ -L $BROOKLYN_ROOT && -d $BROOKLYN_ROOT ]]; then
    rm -f $BROOKLYN_ROOT
fi
# Remove the symbolic link "/var/log/brooklyn" if exists (means that we are upgrading brooklyn)
BROOKLYN_LOG=/var/log/brooklyn
if [[ -L $BROOKLYN_LOG && -d $BROOKLYN_LOG ]]; then
    rm -f $BROOKLYN_LOG
fi
