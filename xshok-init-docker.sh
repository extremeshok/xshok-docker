#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Starts your docker-compose based containers properly
#
# Automatically creates volume directories and touches volume files
# Stops all running containers
# Removes any orphaned containers
# Pull/download dependencies and images
# Forces recreation of all containers and will build required containers
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Assumptions: Docker and Docker-compose Installed
#
# Tested on KVM, VirtualBox and Dedicated Server
#
# Notes:
# Script must be placed into the same directory as the docker-compose.yml
#
# Usage:
# wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-init-docker.sh -O xshok-init-docker.sh && chmod +x xshok-init-docker.sh
# bash xshok-init-docker.sh
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${dirname}" || exit 1

if [ ! -f "docker-compose.yml" ] ; then
  echo "ERROR: docker-compose.yml not found, script must be run in the same directory"
  exit 1
fi

#Automatically create required volume dirs
volumedir_array=$(grep "device: \${PWD}/volumes/" docker-compose.yml)
for volumedir in $volumedir_array ; do
  if [[ $volumedir =~ "\${PWD}" ]]; then
    volumedir="${volumedir/\$\{PWD\}\//}"
    if [ ! -d "$volumedir" ] ; then
      if [ ! -f "$volumedir" ] && [[ $volumedir != *.* ]] ; then
        echo "Creating dir: $volumedir"
        mkdir -p "$volumedir"
        chmod 755 "$volumedir"
      elif [ ! -d "$volumedir" ] && [[ $volumedir == *.* ]] ; then
        echo "Creating file: $volumedir"
        touch -p "$volumedir"
      fi
    fi
  fi
done

docker-compose down --remove-orphans
# detect if there are any running containers and manually stop and remove them
if docker ps -q 2> /dev/null ; then
  docker stop $(docker ps -q)
  sleep 1
  docker rm $(docker ps -q)
fi

docker-compose pull --include-deps
docker-compose up -d --force-recreate --build
