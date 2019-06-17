#!/bin/bash

ENV=dev ./setup.sh

docker-compose down --remove-orphans

docker-compose up -d
docker build .
docker-compose up -d --force-recreate --build devproxy
