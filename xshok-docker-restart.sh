#!/usr/bin/env bash

cd /datastore || exit

docker-compose down
sync
sleep 3
docker-compose up -d
