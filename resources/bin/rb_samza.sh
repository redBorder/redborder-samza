#!/bin/bash

#######################################################################
# Copyright (c) 2016 ENEO Tecnología S.L.
# This file is part of redBorder.
# redBorder is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# redBorder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License License for more details.
# You should have received a copy of the GNU Affero General Public License License
# along with redBorder. If not, see <http://www.gnu.org/licenses/>.
#######################################################################

source /etc/profile
SAMZA_DIR="/usr/lib/samza"
HADOOP_DIR="/usr/lib/hadoop"
HADOOP_BIN="${HADOOP_DIR}/bin"

function usage(){
  echo "$0 [-h][-e][-u][-k][-l][-c <count>][/-m <memory>]"
  echo "    -h: print this help"
  echo "    -e: execute the task"
  echo "    -v: print the version"
  echo "    -k: kill running tasks"
  echo "    -l: list running tasks"
  echo "    -t: set type of task: enrichment, indexing, pms, all (default)"
  echo "    -c: set samza containers (default: 1)"
  echo "    -m: set samza container memory (default: 1024)"
  echo "    -s: show samza container info"
  echo " example:"
  echo "   - upload: rb_samza.sh -t enrichment -e"
  echo "   -   kill: rb_samza.sh -t enrichment -k"
  echo "   -   list: rb_samza.sh -l"
  exit 1
}

f_execute=0
f_kill=0
f_list=0
f_cont=0
f_mem=0
containers=1
memory=1024
f_version=0
f_type="all"
f_show=0

while getopts "hevklt:c:m:s" name
do
  case $name in
    h) usage;;
    e) f_execute=1;;
    k) f_kill=1;;
    l) f_list=1;;
    v) f_version=1;;
    t) f_type=$OPTARG;;
    c) f_cont=1; containers=$OPTARG;;
    m) f_mem=1; memory=$OPTARG;;
    s) f_show=1;;
  esac
done

if [ $f_version -eq 1 ]; then
  ls $SAMZA_DIR/rb-samza-bi/app/rb-samza-bi.tar.gz -l|sed 's/.*-> //'|awk '{print $1}' | sed 's/rb-samza-bi-//' | sed 's/-.*$//'
else
  [ $f_cont -eq 1 ] && rb_set_samzacontainers.rb -c $containers
  [ $f_mem -eq 1 ] && rb_set_samzacontainersmemory.rb -m $memory
  [ $f_show -eq 1 ] && rb_set_samzacontainers.rb -s && rb_set_samzacontainersmemory.rb -s


  ## Kill apps if -k option is set ###########################################################
  if [ $f_kill -eq 1 ]; then
    if [ "x$f_type" == "xall" ] ; then
      kill_app_types="enrichment location indexing malware pms iot"
    else
      kill_app_types="$f_type"
    fi

    for app_type in $kill_app_types ; do
      application="$($HADOOP_BIN/yarn application -list | grep $app_type | awk '{print $1}')"
      for n in $application ; do
        $HADOOP_BIN/yarn application -kill $n &>/dev/null
        echo "Killed application $n ($app_type)"
      done
    done    
  fi
  ################################################################################################

  ## List apps if -l option is set ###############################################################
  if [ $f_list -eq 1 ]; then
     timeout 60 $HADOOP_BIN/yarn application -list | egrep "(Samza|Application-Id)"
  fi
  ################################################################################################

  ## Execute apps if -e option is set ############################################################
  if [ $f_execute -eq 1 ]; then

    if [ "x$f_type" == "xall" ] ; then
      exec_app_types="enrichment location indexing"
    else
      exec_app_types="$f_type"
    fi
    
    for app_type in $exec_app_types ; do

      if [ "x$app_type" == "xenrichment" -o "x$app_type" == "xindexing" ] ; then
        package_name="rb-samza-bi"
      else
        package_name="rb-samza-$app_type"
      fi

      rm -rf ${SAMZA_DIR}/${package_name}/bin/*
      rm -rf ${SAMZA_DIR}/${package_name}/lib/*
      tar xfz ${SAMZA_DIR}/${package_name}/app/${package_name}.tar.gz -C ${SAMZA_DIR}/${package_name}
      
      application_list="$($HADOOP_BIN/yarn application -list)"
      if [ $? -eq 0 ] ; then
        application="$(echo "$application_list" | grep $app_type | awk '{print $1}')"
        if [ "x$application" == "x" ] ; then
          ${SAMZA_DIR}/${package_name}/bin/run-job.sh \
            --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory \
            --config-path=file:$SAMZA_DIR/${package_name}/config/$app_type.properties
        else
          echo "Application $application ($app_type) is already running."
        fi
      fi


    done
  fi

fi