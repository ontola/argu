#!/bin/bash

ENV=test ./setup.sh

docker-compose down

docker-compose up -d
docker build .
docker-compose up -d --force-recreate devproxy

docker exec devproxy_argu_1 sed -i -e 's/staging.argu.co/argu.localtest/g' public/packs/manifest.json
docker restart devproxy_argu_1

echo "Don't forget to run 'bundle exec rake test:setup' if you haven't already"
