#!/usr/bin/env bash
set -e

CLUSTER_NAME="muchtodo"
IMAGE_NAME="muchtodo-backend:local"
KIND_NODE_IMAGE="kindest/node:v1.30.0"

if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config kubernetes/kind-config.yaml \
    --image "${KIND_NODE_IMAGE}" \
    --wait 5m
fi

docker build -t "${IMAGE_NAME}" .

kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

kubectl rollout status deployment/mongodb -n muchtodo --timeout=180s
kubectl rollout status deployment/backend -n muchtodo --timeout=180s

kubectl get pods -n muchtodo -o wide
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo
