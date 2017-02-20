#!/bin/bash
docker build . -t argu.proxy && docker run -p 3031:3031 -p 443:443 -v $(pwd)/www:/etc/nginx/www argu.proxy
