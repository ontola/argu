#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/../test

docker pull registry.gitlab.com/ontola/argu:base-pw
docker build -t registry.gitlab.com/ontola/argu:base-pw --cache-from registry.gitlab.com/ontola/argu:base-pw .
docker push registry.gitlab.com/ontola/argu:base-pw
