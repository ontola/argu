#!/bin/bash
./setup.sh

docker-compose down

RESTRICT_EXTERNAL_NETWORK=false docker-compose up -d
docker build .
RESTRICT_EXTERNAL_NETWORK=false docker-compose up -d --force-recreate devproxy

while getopts e: option
do
case "${option}"
in
e) docker-compose stop ${OPTARG};;
esac
done
