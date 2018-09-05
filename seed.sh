#!/bin/bash

echo seeding $1

RESTRICT_EXTERNAL_NETWORK=false docker-compose run $1 bundle exec rake db:setup
