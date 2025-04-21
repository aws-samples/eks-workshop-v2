set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl rollout status -n nginx deployment/nginx --timeout=40s

  POD_COUNT=$(kubectl get pod -n nginx -l app.kubernetes.io/name=nginx -o json | jq -r ".items | length")
  
  if [[ $POD_COUNT -eq 3 ]]; then
    exit 0
  fi

  >&2 echo "There should be 3 pods running"
  exit 1
}

"$@"
