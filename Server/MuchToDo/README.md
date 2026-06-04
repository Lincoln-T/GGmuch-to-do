# MuchTodo Container Assessment

This project containerizes the MuchTodo Go backend API and deploys it locally using Docker Compose and Kubernetes with Kind.

## Application Overview

Backend: Go API located in cmd/api/main.go
Port: 8080
Database: MongoDB
Health endpoint: GET /health
Cache: disabled using ENABLE_CACHE=false

## Project Files

Dockerfile: multi-stage Dockerfile for the Go backend.
.dockerignore: excludes unnecessary files from Docker build context.
docker-compose.yml: runs MongoDB and the backend locally.
kubernetes/: contains namespace, MongoDB, backend, service, PVC, ConfigMap, Secret, Kind config, and Ingress manifests.
scripts/: contains helper scripts for Docker and Kubernetes.
evidence/: contains screenshots required for deployment evidence.

## Docker Setup

Build the Docker image:

./scripts/docker-build.sh

Run the backend and MongoDB:

./scripts/docker-run.sh

Manual command:

docker-compose up -d --build

Check running containers:

docker ps

Test the health endpoint:

curl http://localhost:8080/health

Expected response:

{"cache":"disabled","database":"ok"}

Stop Docker Compose:

docker-compose down

## Kubernetes Setup With Kind

Create the Kind cluster:

kind create cluster --name muchtodo --config kubernetes/kind-config.yaml --image kindest/node:v1.30.0 --wait 5m

Load the backend Docker image into Kind:

kind load docker-image muchtodo-backend:local --name muchtodo

Apply Kubernetes manifests:

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

Or deploy using the script:

./scripts/k8s-deploy.sh

Check Kubernetes resources:

kubectl get pods -n muchtodo -o wide
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo

Access the backend through NodePort:

curl http://localhost:8080/health

Expected response:

{"cache":"disabled","database":"ok"}

## Cleanup

Remove Kubernetes deployment and Kind cluster:

./scripts/k8s-cleanup.sh

Stop Docker Compose:

docker-compose down

## Environment Variables

PORT=8080
MONGO_URI
DB_NAME=much_todo_db
JWT_SECRET_KEY
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=false
LOG_LEVEL=INFO
LOG_FORMAT=json

## Evidence

Required screenshots are stored in:

evidence/docker/
evidence/kubernetes/

Docker evidence:
- Docker build completion.
- Docker Compose containers running.
- Application response through Docker Compose.

Kubernetes evidence:
- Kind cluster creation.
- Kubernetes pods running.
- Kubernetes services.
- Kubernetes ingress.
- Application response through Kubernetes NodePort.
