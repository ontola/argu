#!/bin/bash

if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

rm -f /usr/share/ca-certificates/devproxy.crt
rm -f devproxyCA/*.pem devproxyCA/*.attr devproxyCA/*.old
rm -f devproxyCA/serial devproxyCA/index.txt
rm -f devproxyCA/private/*.pem
rm -f ssl/*.pem ssl/*.key ssl/*.crt
