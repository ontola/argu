#!/bin/bash

check_cmd() {
  command -v $1 > /dev/null || echo_err "command $1 not found"
}

echo_err() {
  echo $1
  exit 1
}

# Check required commands
check_cmd docker
check_cmd minikube
check_cmd kubectl
check_cmd helm
check_cmd tiller

# Check service statuses
minikube status > /dev/null || echo_err "minikube has issues"
kubectl cluster-info > /dev/null || echo_err "kubectl has cluster connection issues"

# Check configs
kubectl get secret argu-gcr-key > /dev/null || echo_err "Kubernetes not authenticated to pull argu images"

echo "system looks healthy"
