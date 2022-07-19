#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path

if !(grep -x "127.0.0.1\s*.argu\.local.*" /etc/hosts)
then
  echo 127.0.0.1 argu.localdev argu.localtest >> /etc/hosts
fi

sudo ./setup_certificate.sh
./setup_env.sh

echo "Install finished"
