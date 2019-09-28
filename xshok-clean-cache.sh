#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Empties cache volumes
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################

cd /datastore
rm -rf /datastore/volumes/nginx-cache/*
rm -rf /datastore/volumes/nginx-pagespeed/*
rm -rf /datastore/volumes/redis/*
rm -rf /datastore/volumes/www-cache/*
rm -rf /datastore/volumes/www-html/wp-content/cache/*
