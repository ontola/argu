#!/bin/bash

ENV=test ./setup.sh

docker-compose down --remove-orphans

docker-compose up -d
docker build .
docker-compose up -d --force-recreate --build devproxy

docker restart devproxy_argu_1

echo "Don't forget to run the following command if you haven't already: bundle exec rake test:setup"
