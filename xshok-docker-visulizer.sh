#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################

dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${dirname}" || exit 1

if [ ! -f "docker-compose.yml" ] ; then
  echo "ERROR: docker-compose.yml not found, must be run in the same directory"
  exit 1
fi

mkdir -p /tmp/docker-viz

if [ -d "/tmp/docker-viz" ] && [ -w "/tmp/docker-viz" ] ; then
  echo "Generating Docker Visualisations"
  chmod 777 /tmp/docker-viz
  docker-compose config > /tmp/docker-viz/docker-compose.yml
  docker run --rm -it --name dcv -v /tmp/docker-viz:/input:rw pmsipilot/docker-compose-viz render -m image -o docker-vis-full.png --horizontal --force /input/docker-compose.yml
  mv -f /tmp/docker-viz/docker-vis-full.png "${dirname}/docker-vis-full.png"
  docker run --rm -it --name dcv -v /tmp/docker-viz:/input:rw pmsipilot/docker-compose-viz render -m image -o docker-vis-novols.png --horizontal --no-volumes --force /input/docker-compose.yml
  mv -f /tmp/docker-viz/docker-vis-novols.png "${dirname}/docker-vis-novols.png"
  rm -rf /tmp/docker-viz
  echo "Completed, images saved to ${dirname}"

else
  echo "ERROR, failed to create temp dir or not writable: /tmp/docker-viz"
  exit 1
fi
