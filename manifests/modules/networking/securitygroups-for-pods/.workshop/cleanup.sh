#!/bin/bash

set -e

logmessage "Deleting Security Group policies..."

kubectl delete SecurityGroupPolicy --all -A

sleep 5

# Clear the catalog pods so the SG can be deleted
kubectl rollout restart -n catalog deployment/catalog