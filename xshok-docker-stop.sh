#!/usr/bin/env bash

dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${dirname}" || exit 1
echo "$dirname"

docker-compose down
sync
sleep 3
