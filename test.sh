#!/bin/bash
BACKEND_HOST=argu:3000 ./setup.sh

docker-compose down

ENV_FILE=./.env.test docker-compose up -d
docker build .
ENV_FILE=./.env.test docker-compose up -d --force-recreate devproxy

echo "Don't forget to run 'bundle exec rake test:setup' if you haven't already"
