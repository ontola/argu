#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install kubernetes-cli
elif [[ "$OSTYPE" == "win32" ]]; then
  choco install kubernetes-cli
else
  sudo apt-get update && sudo apt-get install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubectl
fi

