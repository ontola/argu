#!/bin/bash

echo building $1

docker build ../$1/ --cache-from registry.gitlab.com/ontola/$1:staging --tag registry.gitlab.com/ontola/$1:staging --build-arg HOSTNAME=staging.argu.co --build-arg RAILS_ENV=staging

./restart.sh $1
