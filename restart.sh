#!/bin/bash

echo restarting $1

docker-compose up -d --force-recreate --build $1
docker-compose up -d --force-recreate --build $1_sidekiq
docker-compose up -d --force-recreate --build $1_subscriber
