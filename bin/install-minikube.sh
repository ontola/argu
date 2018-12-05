#!/bin/bash

# TODO: detect hypervisor support

if [[ "$OSTYPE" == "darwin"* ]]; then
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.30.0/minikube-darwin-amd64
  chmod +x minikube
  sudo cp minikube /usr/local/bin/
  rm minikube
elif [[ "$OSTYPE" == "win32" ]]; then
  echo "Windows not yet supported (so fix this file)"
  exit 1
else
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.30.0/minikube-linux-amd64
  chmod +x minikube
  sudo cp minikube /usr/local/bin/
  rm minikube
fi

