set -e

before() {
  echo "noop"
}

after() {
  helm ls -n ui -o json | jq -e '.[] | select(.name=="ui")'

  kubectl rollout status -n ui deployment/ui --timeout=10s
}

"$@"
