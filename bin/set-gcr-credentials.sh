#!/bin/bash

if [ ! $(kubectl get secret argu-gcr-key >/dev/null 2>/dev/null) ]; then
  echo "Image pull secret not found, initializing"

  email=${1:-"$(whoami)@argu.co"}
  echo "Using email '$email'"

  kubectl create secret docker-registry argu-gcr-key \
    --docker-server=https://eu.gcr.io \
    --docker-username=oauth2accesstoken \
    --docker-password="$(gcloud auth print-access-token)" \
    --docker-email=$email
else
  echo "Image pull secret already present, skipping"
fi

kubectl patch serviceaccount default \
        -p '{"imagePullSecrets": [{"name": "argu-gcr-key"}]}'
