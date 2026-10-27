#!/bin/bash

set -e

echo "Cleaning up Kubernetes Basics module resources..."

# Clean up pods
echo "Cleaning up pods..."
kubectl delete pod ui-pod -n ui --ignore-not-found=true
kubectl delete pod test-pod --ignore-not-found=true

# Clean up secrets
echo "Cleaning up secrets..."
kubectl delete secret catalog-db -n catalog --ignore-not-found=true

# Clean up daemonsets
echo "Cleaning up daemonsets..."
kubectl delete daemonset log-collector -n kube-system --ignore-not-found=true

# Clean up jobs and cronjobs
echo "Cleaning up jobs and cronjobs..."
kubectl delete job data-processor -n catalog --ignore-not-found=true
kubectl delete cronjob catalog-cleanup -n catalog --ignore-not-found=true
kubectl delete job manual-cleanup -n catalog --ignore-not-found=true

# Delete any jobs that start with catalog-cleanup (created by CronJob)
kubectl get jobs -n catalog -o name 2>/dev/null | grep "job/catalog-cleanup" | xargs -r kubectl delete -n catalog --ignore-not-found=true

# Clean up namespaces (do this last as it will clean up any remaining resources)
echo "Cleaning up namespaces..."
kubectl delete namespace ui --ignore-not-found=true
kubectl delete namespace catalog --ignore-not-found=true

echo "Kubernetes Basics module cleanup completed."
