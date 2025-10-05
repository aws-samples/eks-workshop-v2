#!/usr/bin/env bash
set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  echo "Waiting for UI deployment to be available..."
  
  # Wait for deployment to exist first
  timeout=60
  while [ $timeout -gt 0 ]; do
    if kubectl get deployment ui -n ui >/dev/null 2>&1; then
      echo "UI deployment found"
      break
    fi
    echo "Waiting for UI deployment to be created..."
    sleep 2
    timeout=$((timeout-2))
  done
  
  if [ $timeout -le 0 ]; then
    echo "Timeout waiting for UI deployment to be created"
    exit 1
  fi
  
  echo "Waiting for UI deployment to be ready..."
  kubectl wait --for=condition=available deployment/ui -n ui --timeout=300s
  
  echo "Waiting for UI pods to be ready..."
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ui -n ui --timeout=300s
  
  echo "Waiting for UI service endpoints..."
  kubectl wait --for=jsonpath='{.subsets[0].addresses[0].ip}' endpoints/ui -n ui --timeout=300s
  
  echo "Verifying service is accessible..."
  
  # Test that the service exists and has endpoints
  kubectl get service -n ui ui
  kubectl get endpoints -n ui ui
  
  # Verify that the service has at least one endpoint
  endpoint_count=$(kubectl get endpoints -n ui ui -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
  if [ "$endpoint_count" -eq 0 ]; then
    echo "Error: Service has no endpoints"
    kubectl describe endpoints -n ui ui
    exit 1
  fi
  
  echo "Service verification completed successfully - $endpoint_count endpoint(s) available"
}

"$@"