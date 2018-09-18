#!/bin/bash

rm .env
ln -s .env.test .env

BACKEND_HOST=argu:3000 ./setup.sh

docker-compose down

docker-compose up -d
docker build .
docker-compose up -d --force-recreate devproxy

echo "Don't forget to run 'bundle exec rake test:setup' if you haven't already"
