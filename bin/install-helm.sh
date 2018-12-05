#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install kubernetes-helm
elif [[ "$OSTYPE" == "win32" ]]; then
  choco install kubernetes-helm
else
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
fi

helm init
