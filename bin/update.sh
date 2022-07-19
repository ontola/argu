#!/bin/bash

docker-compose exec apex sh -c "bundle install && bundle exec rake db:prepare"
docker-compose exec token sh -c "bundle install && bundle exec rake db:prepare"
docker-compose exec email sh -c "bundle install && bundle exec rake db:prepare"
docker-compose exec libro_client sh -c "yarn install && yarn run t10s:compile"
