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

# displays a jstack thread dump showing only "really-running" threads
#
# takes a PID as argument
# filters jstack to remove wait/blocked threads and known
# wait points which report themselves as active (e.g. socket.read)
#
# very useful for spot-checking what is *actually* consuming CPU


jstack $@ | awk '
function onTraceBegin() {
	onTraceEnd()
	data["lineCount"]=0
	data["head"]=$0
}

function onTraceEnd() {
	if ("head" in data) {
		if (data["active"] && "topClass" in data) {
			print data["head"]
			for (l=1; l<=data["lineCount"]; l++) { print lines[l] }
			print ""
		}
	}
	delete lines
	delete data
}

function startsWith(whole,prefix) {
	return (substr(whole,1,length(prefix))==prefix);
}

{
  if (!match($0,"[^\\s]")) onTraceEnd();
  else if (substr($0,1,1)=="\"") onTraceBegin();
  else if ("head" in data) {
	lc = ++data["lineCount"];
	lines[lc]=$0
	if (lc==1) {
		state=data["state"]=$2;
		data["active"] = !(state=="WAITING" || state=="BLOCKED" || state=="TIMED_WAITING")
	}
	if ($1=="at") {
		if ("topClass" in data) {
		} else {
			data["topClass"] = $0;
			tc = $2;
			if (data["active"]) {
				if (startsWith(tc,"java.net") || startsWith(tc,"sun.nio")) data["active"]=false;
			}
		}
	}
  }
}
END {
	onTraceEnd();
}
'
