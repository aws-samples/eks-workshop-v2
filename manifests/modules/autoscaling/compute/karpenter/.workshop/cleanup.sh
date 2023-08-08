#!/bin/bash

set -e

echo "Deleting Karpenter provisioners..."

kubectl delete provisioner --all > /dev/null
kubectl delete awsnodetemplate --all > /dev/null

echo "Waiting for Karpenter nodes to be removed..."

EXIT_CODE=0

timeout --foreground -s TERM 30 bash -c \
    'while [[ $(kubectl get nodes --selector=type=karpenter -o json | jq -r ".items | length") -gt 0 ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "Warning: Karpenter nodes did not clean up"
fi
