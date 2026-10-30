set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Clean up network policies applied during the lab
  kubectl delete networkpolicy --all -n ui --ignore-not-found
  kubectl delete networkpolicy --all -n catalog --ignore-not-found

  # Restart affected pods to clear any cached connection state
  kubectl rollout restart deployment/catalog -n catalog
  kubectl rollout restart deployment/ui -n ui
  kubectl rollout status deployment/catalog -n catalog --timeout=120s
  kubectl rollout status deployment/ui -n ui --timeout=120s
}

"$@"
