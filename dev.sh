#!/bin/bash

ENV=dev ./setup.sh

docker-compose down

docker-compose up -d
docker build .
docker-compose up -d --force-recreate devproxy
