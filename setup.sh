#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  IP=$(ifconfig | awk '/broadcast/' | awk '/inet /{print $2}')
# elif [[ "$OSTYPE" == "win32" ]]; then
  echo "Windows not yet implemented (so ticket+PR)"
  # TODO
else
  IP=$(hostname -I | awk -F" " '{print $1}')
fi

NGINXIP=$(head -1 ./nginx.conf 2>/dev/null | tr -d '# ')

echo "IP: $IP"
echo "NGINX IP: $NGINXIP"

IP=$IP ENV=$ENV ./setup_environment.rb

# Set postgres vars once
PG_USERNAME=$(openssl rand -hex 32)
PG_PASSWORD=$(openssl rand -hex 32)

write_env() {
    echo "writing .env for $1"
    sed "s/{postgres_user}/$PG_USERNAME/g" .env.template > ./.env.$1
    sed -i "s/{postgres_password}/$PG_PASSWORD/g" ./.env.$1
    sed -i "s/{argu_client_id}/$ARGU_CLIENT_ID/g" ./.env.$1
    sed -i "s/{argu_client_secret}/$ARGU_CLIENT_SECRET/g" ./.env.$1
    sed -i "s/{frontend_token}/$FRONTEND_TOKEN/g" ./.env.$1
    sed -i "s/{service_token}/$SERVICE_TOKEN/g" ./.env.$1
    sed -i "s/{database_suffix}/$DB_SUFFIX/g" ./.env.$1
    sed -i "s/{secret}/$SECRET/g" ./.env.$1
    sed -i "s/{tld}/local$1/g" ./.env.$1
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
    FRONTEND_TOKEN=$(./generate_jwt.sh $SECRET service afe)
    SERVICE_TOKEN=$(./generate_jwt.sh $SECRET service)
    write_env test;
fi

# Exit if script if host IP matches nginx config IP
if [ $IP = $NGINXIP ]; then
  echo "Host IP matches the IP configured in nginx.conf, skipping certs creation."
  exit 0
fi

# Generate root certificate
if [ ! -f /usr/share/ca-certificates/devproxy.crt ]; then
  sudo openssl req -x509 -nodes -days 365 \
       -config openssl.cfg \
       -newkey rsa:4096 \
       -subj "/C=NL/ST=Utrecht/L=Utrecht/O=Argu/OU=Argu Root/CN=argu.localdev" \
       -keyout devproxyCA/private/cakey.pem \
       -out devproxyCA/cacert.pem
  # Install in system
  sudo ln -s $PWD/devproxyCA/cacert.pem /usr/share/ca-certificates/devproxy.crt
  sudo dpkg-reconfigure p critical ca-certificates
  echo "4"
  # Install in firefox
  for certDB in $(find  ~/.mozilla* -name "cert8.db")
  do
    certDir=$(dirname ${certDB});
    certutil -A -n "Argu root" -t "TCu,Cuw,Tuw" -i "devproxyCA/cacert.pem" -d ${certDir}
  done
  # Install in chrome
  certutil -A -n "Argu root" -t "TCu,Cuw,Tuw" -i "devproxyCA/cacert.pem" -d sql:$HOME/.pki/nssdb
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
