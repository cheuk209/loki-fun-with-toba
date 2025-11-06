#!/bin/bash

# Stop the Minikube cluster
minikube stop

# Delete the Minikube cluster
minikube delete

# Optionally, you can also delete the Kubernetes resources
kubectl delete -f ../k8s/hello/hello-deployment.yaml
kubectl delete -f ../k8s/loki/loki-deployment.yaml
kubectl delete -f ../k8s/promtail/promtail-daemonset.yaml