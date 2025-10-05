#!/bin/bash

set -e

echo "Cleaning up services module resources..."

# Delete any test pods that might be left over
kubectl delete pod test-pod --ignore-not-found=true

echo "Services module cleanup completed"