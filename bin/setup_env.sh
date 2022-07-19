#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/..

ELASTICSEARCH_URL=${ELASTICSEARCH_URL:-http://elastic:9200}
PG_USERNAME=$(openssl rand -hex 32)
PG_PASSWORD=$(openssl rand -hex 32)
CERTFILE=$(pwd)/docker/nginx/devproxyCA/cacert.pem

write_env() {
    echo "writing .env for $1"

    sed "s/{postgres_user}/$PG_USERNAME/g" .env.template > ./.env.$1
    sed -i.bak "s/{postgres_password}/$PG_PASSWORD/g" ./.env.$1
    sed -i.bak "s/{database_suffix}/$DB_SUFFIX/g" ./.env.$1
    sed -i.bak "s#{elastic_search}#$ELASTICSEARCH_URL#g" ./.env.$1
    sed -i.bak "s/{secret}/$SECRET/g" ./.env.$1
    sed -i.bak "s#{certfile}#$CERTFILE#g" ./.env.$1
    sed -i.bak "s/{tld}/local$1/g" ./.env.$1
    rm ./.env.$1.bak
}

# Create .env.dev
if [ ! -f ./.env.dev ]; then
    SECRET=$(openssl rand -hex 32)
    DB_SUFFIX=production
    write_env dev;
fi

# Create .env.test
if [ ! -f ./.env.test ]; then
    SECRET=$(openssl rand -hex 32)
    DB_SUFFIX=test
    write_env test;
fi
