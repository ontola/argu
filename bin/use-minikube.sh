#!/bin/bash

cpu_total=$(nproc)
cpus=$(expr $cpu_total / 2)

echo "Starting minikube with $cpus cpus and 4 GB mem"

minikube start --cpus $cpus --memory 4096 --kubernetes-version=1.11.0
kubectl config use-context minikube

