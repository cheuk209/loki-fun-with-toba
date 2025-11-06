# Makefile for Loki Proof of Concept Application

.PHONY: start stop

start:
	@echo "Starting Minikube..."
	minikube start
	@echo "Deploying Loki and Hello World application..."
	kubectl apply -k k8s

stop:
	@echo "Stopping Minikube and cleaning up resources..."
	kubectl delete -k k8s
	minikube stop
	@echo "Minikube stopped."