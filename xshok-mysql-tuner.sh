#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Installs and runs mysql-tuner on a mariadb/mysql ubuntu/debian based container
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################

docker-compose exec mysql /bin/bash -c 'apt-get update && apt-get install -y wget perl && wget http://mysqltuner.pl/ -O /tmp/mysqltuner.pl && perl /tmp/mysqltuner.pl --host 127.0.0.1 --user root --pass ${MYSQL_ROOT_PASSWORD}'
