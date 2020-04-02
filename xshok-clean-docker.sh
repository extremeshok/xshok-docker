#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Stops your docker-compose based containers properly
#
# Stops all running containers
# Removes any orphaned containers amd images
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
# wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-clean-docker.sh -O xshok-clean-docker.sh && chmod +x xshok-clean-docker.sh
# bash xshok-clean-docker.sh
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
docker-compose down --remove-orphans

echo "Stopping all containers"
docker stop $(docker ps -q)
echo "Removing images, will NOT remove volumes"
docker system prune -a -f

journalctl --vacuum-size=64M --vacuum-time=2d;
journalctl --rotate
