#!/usr/bin/env bash
set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  echo "Waiting for UI deployment to be available..."
  
  kubectl wait --for=condition=available deployment/ui -n ui --timeout=300s
  
  echo "Waiting for UI service endpoints..."
  kubectl wait --for=jsonpath='{.subsets[0].addresses[0].ip}' endpoints/ui -n ui --timeout=300s
}

"$@"
