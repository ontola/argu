#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/..

git pull
git submodule update --recursive

./bin/restart.sh
./bin/update.sh
