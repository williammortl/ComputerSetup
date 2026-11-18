#!/usr/bin/env bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME="$1"
CONTEXT_NAME="kind-${CLUSTER_NAME}"

echo "Creating kind cluster: ${CLUSTER_NAME}"
kind create cluster --name "${CLUSTER_NAME}"

echo
echo "Switching kubectl to context: ${CONTEXT_NAME}"
kubectl config use-context "${CONTEXT_NAME}"

echo
echo "Cluster status:"
kubectl cluster-info

echo
kubectl get nodes

