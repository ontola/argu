#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/..

if [[ $(readlink -f .env) == *test ]]; then
  docker-compose exec testrunner bundle exec rake test:setup

  echo "Open your browser at https://argu.localtest/argu"
else
  docker-compose exec testrunner bundle exec rake dev:setup

  echo "Open your browser at https://argu.localdev/argu"
fi

