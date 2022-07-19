#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/..

LIBRO_TAG=$(git rev-parse HEAD)
APEX_TAG=$(git submodule status --cached services/apex | awk '{print $1;}' | tr -cd '[:alnum:]')
EMAIL_TAG=$(git submodule status --cached services/email_service | awk '{print $1;}' | tr -cd '[:alnum:]')
TOKEN_TAG=$(git submodule status --cached services/token_service | awk '{print $1;}' | tr -cd '[:alnum:]')

source .env

docker-compose down

COMPOSE_PROFILES=$COMPOSE_PROFILES LIBRO_TAG=$LIBRO_TAG APEX_TAG=$APEX_TAG EMAIL_TAG=$EMAIL_TAG TOKEN_TAG=$TOKEN_TAG docker-compose up --no-deps -d --remove-orphans --force-recreate
