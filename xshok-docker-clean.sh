#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
echo "Stopping all containers"
docker stop $(docker ps -q)
echo "Removing images, will NOT remove volumes"
docker system prune -a -f
