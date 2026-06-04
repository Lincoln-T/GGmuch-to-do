#!/usr/bin/env bash
set -e

kubectl delete namespace muchtodo --ignore-not-found=true

if kind get clusters | grep -q "^muchtodo$"; then
  kind delete cluster --name muchtodo
fi
