#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  IP=$(ifconfig | awk '/broadcast/' | awk '/inet /{print $2}')
# elif [[ "$OSTYPE" == "win32" ]]; then
  # TODO
else
  IP=$(hostname -I | awk -F" " '{print $1}')
fi

echo "IP: $IP"

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=NL/ST=Utrecht/L=Utrecht/O=Argu/OU=Argu Development/CN=argu.local" -keyout ./ssl/nginx.key -out ./ssl/nginx.crt
if [ ! -f ./nginx.conf ]; then
    sed "s/{your_local_ip}/$IP/g" nginx.conf.template > ./nginx.conf
fi
wait
./run.sh
