set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl rollout status -n ui deployment/ui --timeout=40s

  POD_COUNT=$(kubectl get pod -n ui -o json | jq -r ".items | length")
  
  if [[ $POD_COUNT -eq 3 ]]; then
    exit 0
  fi

  >&2 echo "There should be 3 pods running"
  exit 1
}

"$@"
