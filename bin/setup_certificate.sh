#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parent_path/../docker/nginx

if [ ! -f $PWD/devproxyCA/private/.gitkeep ]; then
  mkdir -p $PWD/devproxyCA/private
  touch $PWD/devproxyCA/private/.gitkeep
fi

if [ ! -d $PWD/devproxyCA/.gitkeep ]; then
  mkdir -p $PWD/devproxyCA/
  touch $PWD/devproxyCA/.gitkeep
fi

if [ ! -d $PWD/ssl/.gitkeep ]; then
  mkdir -p $PWD/ssl/
  touch $PWD/ssl/.gitkeep
fi

# Generate root certificate
if [ ! -f $PWD/devproxyCA/cacert.pem ]; then
  echo "Generating cacert.pem, cakey.pem"
  sudo openssl req -x509 -nodes -days 365 \
       -config openssl.cfg \
       -newkey rsa:4096 \
       -subj "/C=NL/ST=Utrecht/L=Utrecht/O=Argu/OU=Argu Root/CN=argu.localdev" \
       -keyout devproxyCA/private/cakey.pem \
       -out devproxyCA/cacert.pem
  # Install in system
  if [[ "$OSTYPE" == "darwin"* ]]; then
    security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db $PWD/devproxyCA/cacert.pem
  else
    sudo dpkg-reconfigure p critical ca-certificates
  fi

  # Install in browsers
  if ! command -v certutil; then
    # Install in firefox
    for certDB in $(find  ~/.mozilla* -name "cert8.db")
    do
      certDir=$(dirname ${certDB});
      certutil -A -n "Argu root" -t "TCu,Cuw,Tuw" -i "devproxyCA/cacert.pem" -d ${certDir}
    done
    # Install in chrome
    mkdir -p $HOME/.pki/nssdb
    certutil -A -n "Argu root" -t "TCu,Cuw,Tuw" -i "devproxyCA/cacert.pem" -d sql:$HOME/.pki/nssdb
  fi
fi

# Generate serial
if [ ! -f devproxyCA/serial ]; then
  echo '1111111E' > devproxyCA/serial
fi

# Create index.txt
if [ ! -f devproxyCA/index.txt ]; then
  touch devproxyCA/index.txt
fi

# Generate CSR
sudo openssl req \
  -config openssl.cfg \
  -nodes \
  -newkey rsa:2048 \
  -keyout ssl/nginx.key \
  -subj "/C=NL/ST=Utrecht/L=Utrecht/O=Argu/OU=Argu Development/CN=argu.localdev" \
  -new -sha256 \
  -out ssl/argu.localdev.csr.pem

# Create signed server cert
sudo openssl ca \
  -batch \
  -config openssl.cfg \
  -extensions server_cert -days 365 -notext -md sha256 \
  -key devproxyCA/private/cakey.pem \
  -outdir ssl \
  -in ssl/argu.localdev.csr.pem \
  -out ssl/nginx.crt

# Create p12 key
sudo openssl pkcs12 -password pass:password -export -inkey $PWD/devproxyCA/private/cakey.pem -in $PWD/devproxyCA/cacert.pem -out $PWD/devproxyCA/cacert.p12

echo "Certificate installed"
