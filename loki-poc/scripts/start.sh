#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=logging
RELEASE_NAME=loki
VALUES_FILE="k8s/helm/values-minimal.yaml"

# Start minikube if not running
if ! minikube status >/dev/null 2>&1; then
  echo "Starting minikube..."
  minikube start --driver=docker --memory=4096 --cpus=2
else
  echo "Minikube already running"
fi

# Ensure namespace exists
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Add/update Helm repo
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# Install/upgrade Loki with minimal values (wait until ready)
helm upgrade --install "$RELEASE_NAME" grafana/loki \
  -n "$NAMESPACE" \
  -f "$VALUES_FILE" \
  --wait --timeout 10m

# Apply promtail and hello kustomize resources into the same namespace
kubectl apply -k k8s -n "$NAMESPACE"

# Show quick status
kubectl get pods -n "$NAMESPACE" -o wide
echo
echo "To forward Loki gateway locally and open in host browser:"
echo "  kubectl -n $NAMESPACE port-forward svc/loki-gateway 3100:3100 &"
echo '  $BROWSER http://127.0.0.1:3100'