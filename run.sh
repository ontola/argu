#!/bin/bash
docker build . -t argu.proxy && docker run -p 3032:3032 -p 443:443 -v $(pwd)/www:/etc/nginx/www argu.proxy
