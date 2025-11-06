#!/bin/bash

# Start Minikube
minikube start

# Set up the Kubernetes context
kubectl config use-context minikube

# Deploy Loki
kubectl apply -k k8s/loki

# Deploy Promtail
kubectl apply -k k8s/promtail

# Deploy Hello World application
kubectl apply -k k8s/hello

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s

echo "Loki, Promtail, and Hello World application have been deployed successfully."