#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path

[ -L ../.env ] && rm ../.env
ln -s .env.dev ../.env

./restart.sh
./update.sh

