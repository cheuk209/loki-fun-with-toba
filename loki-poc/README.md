# Loki Proof of Concept Application

This project is a proof of concept for integrating Loki with a simple "Hello World" application running on Kubernetes using Minikube. The application demonstrates how to collect logs from the Hello World app using Promtail and visualize them with Loki.

## Project Structure

```
loki-poc
├── k8s
│   ├── loki
│   │   ├── loki-config.yaml
│   │   ├── loki-deployment.yaml
│   │   └── loki-service.yaml
│   ├── promtail
│   │   ├── promtail-daemonset.yaml
│   │   └── promtail-config.yaml
│   ├── hello
│   │   ├── hello-deployment.yaml
│   │   └── hello-service.yaml
│   └── kustomization.yaml
├── src
│   └── hello
│       ├── app.js
│       ├── package.json
│       └── Dockerfile
├── scripts
│   ├── start.sh
│   └── stop.sh
├── .dockerignore
├── .gitignore
├── Makefile
└── README.md
```

## Prerequisites

- Minikube installed and running
- kubectl installed
- Docker installed

## Setup Instructions

1. **Start Minikube and Deploy the Application:**
   Run the following command to start the Minikube cluster and deploy all Kubernetes resources:

   ```bash
   ./scripts/start.sh
   ```

2. **Access the Hello World Application:**
   After deployment, you can access the Hello World application using the following command to get the service URL:

   ```bash
   minikube service hello-service --url
   ```

   Open the URL in your browser to see the Hello World message.

3. **View Logs in Loki:**
   Loki will collect logs from the Hello World application via Promtail. You can access Loki's UI to view the logs. The Loki service can be accessed using:

   ```bash
   minikube service loki-service --url
   ```

4. **Stop the Application:**
   To stop the Minikube cluster and clean up the deployed resources, run:

   ```bash
   ./scripts/stop.sh
   ```

## Usage Example

Once the application is running, you can make requests to the Hello World application, and the logs will be collected by Promtail and sent to Loki. You can then query and visualize these logs in the Loki UI.

## License

This project is licensed under the MIT License.