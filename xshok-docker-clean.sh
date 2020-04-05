#!/bin/bash
echo "Stopping all containers"
docker stop $(docker ps -q)
echo "Removing images, will NOT remove volumes"
docker system prune -a -f
