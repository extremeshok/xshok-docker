#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${dirname}" || exit 1
echo "$dirname"

docker-compose down
sync
sleep 3
