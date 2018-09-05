#!/bin/bash

echo restarting $1

ENV_FILE=./.env.test docker-compose up -d --force-recreate $1
ENV_FILE=./.env.test docker-compose up -d --force-recreate $1_sidekiq
ENV_FILE=./.env.test docker-compose up -d --force-recreate $1_subscriber
