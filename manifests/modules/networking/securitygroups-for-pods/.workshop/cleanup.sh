#!/bin/bash

set -e

echo "Deleting Security Group policies..."

kubectl delete SecurityGroupPolicy --all -A > /dev/null

sleep 5

# Clear the catalog pods so the SG can be deleted
kubectl rollout restart -n catalog deployment/catalog > /dev/null