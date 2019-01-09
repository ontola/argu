#!/bin/bash

# Import secret from .env
export $(egrep -v '^#' .env | xargs)

# Generate frontend token jwt
NEW_FRONTEND_TOKEN=$(./generate_jwt.sh $SECRET_TOKEN service afe)
NEW_SERVICE_TOKEN=$(./generate_jwt.sh $SECRET_TOKEN service)

echo "Now run in Argu Rails console: "
echo "token = Doorkeeper::AccessToken.find_or_create_for(Doorkeeper::Application.argu, User::SERVICE_ID, 'service', 1.year.from_now, false); token.update(token: '${NEW_SERVICE_TOKEN}')"
echo "token = Doorkeeper::AccessToken.find_or_create_for(Doorkeeper::Application.argu_front_end, User::COMMUNITY_ID, 'service afe', 1.year.from_now, false); token.update(token: '${NEW_FRONTEND_TOKEN}')"

# Replace ENV vars
sed -i "s/RAILS_OAUTH_TOKEN=.*/RAILS_OAUTH_TOKEN=${NEW_FRONTEND_TOKEN}/g" .env
sed -i "s/SERVICE_TOKEN=.*/SERVICE_TOKEN=${NEW_SERVICE_TOKEN}/g" .env
