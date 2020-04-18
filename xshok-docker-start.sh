#!/bin/bash
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

DIRNAME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${DIRNAME}" || exit 1
echo "${DIRNAME}"

if [ ! -f "docker-compose.yml" ] ; then
  echo "ERROR: docker-compose.yml not found, script must be run in the same directory"
  exit 1
fi

if ! docker-compose config > /dev/null ; then
  echo "ERROR: docker-compose.yml failed config check"
  exit 1
fi

#Automatically create required volume dirs

## remove all comments
TEMP_COMPOSE="/tmp/xs_$(date +"%s")"
sed -e '1{/^#!/ {p}}; /^[\t\ ]*#/d;/\.*#.*/ {/[\x22\x27].*#.*[\x22\x27]/ !{:regular_loop s/\(.*\)*[^\]#.*/\1/;t regular_loop}; /[\x22\x27].*#.*[\x22\x27]/ {:special_loop s/\([\x22\x27].*#.*[^\x22\x27]\)#.*/\1/;t special_loop}; /\\#/ {:second_special_loop s/\(.*\\#.*[^\]\)#.*/\1/;t second_special_loop}}' docker-compose.yml > "$TEMP_COMPOSE"
VOLUMEDIR_ARRAY=$(grep "device: \${PWD}/volumes/" "$TEMP_COMPOSE")
for VOLUMEDIR in $VOLUMEDIR_ARRAY ; do
  if [[ $VOLUMEDIR =~ "\${PWD}" ]]; then
    VOLUMEDIR="${VOLUMEDIR/\$\{PWD\}\//}"
    if [ ! -d "$VOLUMEDIR" ] ; then
      if [ ! -f "$VOLUMEDIR" ] && [[ $VOLUMEDIR != *.* ]] ; then
        echo "Creating dir: $VOLUMEDIR"
        mkdir -p "$VOLUMEDIR"
        chmod 777 "$VOLUMEDIR"
      elif [ ! -d "$VOLUMEDIR" ] && [[ $VOLUMEDIR == *.* ]] ; then
        echo "Creating file: $VOLUMEDIR"
        touch -p "$VOLUMEDIR"
      fi
    fi
  fi
done
rm -f "$TEMP_COMPOSE"

docker-compose down --remove-orphans
# detect if there are any running containers and manually stop and remove them
if docker ps -q 2> /dev/null ; then
  docker stop $(docker ps -q)
  sleep 1
  docker rm $(docker ps -q)
fi

docker-compose pull --include-deps
docker-compose up -d --force-recreate --build
