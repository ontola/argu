#!/bin/bash

# Import secret from .env
export $(egrep -v '^#' .env | xargs)

# Generate frontend token jwt
NEW_FRONTEND_TOKEN=$(./generate_jwt.sh $SECRET_TOKEN -2 1 service)
NEW_SERVICE_TOKEN=$(./generate_jwt.sh $SECRET_TOKEN -2 0 service)

echo "Now run in Argu Rails console: "
echo "Apartment::Tenant.each do"
echo "  token = Doorkeeper::AccessToken.create(application: Doorkeeper::Application.argu, resource_owner_id: User::SERVICE_ID, scopes: 'service', expires_in: 1.year.from_now); token.token = '${NEW_SERVICE_TOKEN}'; token.save(validate: false)"
echo "  token = Doorkeeper::AccessToken.create(application: Doorkeeper::Application.argu_front_end, resource_owner_id: User::COMMUNITY_ID, scopes: 'service', expires_in: 1.year.from_now); token.token = '${NEW_FRONTEND_TOKEN}'; token.save(validate: false)"
echo "end"

# Replace ENV vars
ENV_FILE=$(readlink -f .env)
sed -i "s/SERVICE_TOKEN=.*/SERVICE_TOKEN=${NEW_SERVICE_TOKEN}/g" $ENV_FILE
