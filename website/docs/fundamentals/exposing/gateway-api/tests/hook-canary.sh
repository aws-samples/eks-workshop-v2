set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  # Verify ui-v2 pods are running
  kubectl wait --for=condition=Ready pods -l app.kubernetes.io/version=v2 -n ui --timeout=120s

  # Verify HTTPRoute is accepted
  kubectl get httproute ui-route -n ui -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' | grep -q "True"
}

"$@"
