set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl rollout status -n ui deployment/ui --timeout=60s
  
  # Wait for all 3 pods to be ready
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ui -n ui --timeout=60s

  POD_COUNT=$(kubectl get pod -n ui -l app.kubernetes.io/name=ui -o json | jq -r ".items | length")
  
  if [[ $POD_COUNT -eq 3 ]]; then
    exit 0
  fi

  >&2 echo "There should be 3 pods running"
  exit 1
}

"$@"