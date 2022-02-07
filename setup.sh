#!/bin/bash

ELASTICSEARCH_URL=${ELASTICSEARCH_URL:-http://elastic:9200}

# Set postgres vars once
PG_USERNAME=$(openssl rand -hex 32)
PG_PASSWORD=$(openssl rand -hex 32)

write_env() {
    echo "writing .env for $1"

    sed "s/{postgres_user}/$PG_USERNAME/g" .env.template > ./.env.$1
    sed -i.bak "s/{postgres_password}/$PG_PASSWORD/g" ./.env.$1
    sed -i.bak "s/{argu_client_id}/$ARGU_CLIENT_ID/g" ./.env.$1
    sed -i.bak "s/{argu_client_secret}/$ARGU_CLIENT_SECRET/g" ./.env.$1
    sed -i.bak "s/{frontend_token}/$FRONTEND_TOKEN/g" ./.env.$1
    sed -i.bak "s/{service_token}/$SERVICE_TOKEN/g" ./.env.$1
    sed -i.bak "s/{database_suffix}/$DB_SUFFIX/g" ./.env.$1
    sed -i.bak "s#{elastic_search}#$ELASTICSEARCH_URL#g" ./.env.$1
    sed -i.bak "s/{secret}/$SECRET/g" ./.env.$1
    sed -i.bak "s/{tld}/local$1/g" ./.env.$1
    rm ./.env.$1.bak
}

# Create .env.dev
if [ ! -f ./.env.dev ]; then
    SECRET=$(openssl rand -hex 32)
    echo argu_client_id:
    read -s ARGU_CLIENT_ID
    echo argu_client_secret:
    read -s ARGU_CLIENT_SECRET
    echo frontend_token:
    read -s FRONTEND_TOKEN
    echo service_token:
    read -s SERVICE_TOKEN
    DB_SUFFIX=production
    write_env dev;
fi

# Create .env.test
if [ ! -f ./.env.test ]; then
    SECRET=$(openssl rand -hex 32)
    ARGU_CLIENT_ID=client_id
    ARGU_CLIENT_SECRET=client_secret
    DB_SUFFIX=test
    FRONTEND_TOKEN=$(./generate_jwt.sh $SECRET -2 1 service)
    SERVICE_TOKEN=$(./generate_jwt.sh $SECRET -2 0 service)
    write_env test;
fi

ENV=$ENV ./setup_environment.rb
