#!/bin/bash

echo restarting $1

docker-compose up -d --force-recreate $1
docker-compose up -d --force-recreate $1_sidekiq
docker-compose up -d --force-recreate $1_subscriber
