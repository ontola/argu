#!/bin/bash

echo building $1

docker build ../$1/ --cache-from eu.gcr.io/active-gasket-113610/$1:staging --tag eu.gcr.io/active-gasket-113610/$1:staging --build-arg HOSTNAME=staging.argu.co --build-arg RAILS_ENV=staging

./restart.sh $1
