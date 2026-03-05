#!/usr/bin/env bash
set -Eeuo pipefail

before() {
    echo "noop"
}

after() {
    echo "Waiting for UI pod to be ready..."
    kubectl wait --for=condition=ready pod/ui-pod -n ui --timeout=300s
    
    echo "Verifying ConfigMap is accessible..."
    
    # Check that ConfigMap exists
    kubectl get configmap ui -n ui
    
    # Verify the pod has the environment variable from ConfigMap
    env_var=$(kubectl exec -n ui ui-pod -- env | grep RETAIL_UI_ENDPOINTS_CATALOG || echo "")
    if [ -z "$env_var" ]; then
        echo "Error: RETAIL_UI_ENDPOINTS_CATALOG environment variable not found"
        echo "Available environment variables:"
        kubectl exec -n ui ui-pod -- env | grep RETAIL_UI || echo "No RETAIL_UI variables found"
        exit 1
    fi
    
    echo "Found environment variable: $env_var"
    echo "ConfigMap test completed successfully"
}

"$@"
