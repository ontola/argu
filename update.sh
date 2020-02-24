#!/bin/bash

docker-compose pull
./dev.sh
docker exec devproxy_argu_1 bundle exec rake db:migrate
docker exec devproxy_token_1 bundle exec rake db:migrate
docker exec devproxy_email_1 bundle exec rake db:migrate
