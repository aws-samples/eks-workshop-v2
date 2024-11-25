set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for condition=available --timeout=120s -n kubecost deployment kubecost-cost-analyzer
  kubectl wait --for condition=available --timeout=120s -n kubecost deployment kubecost-prometheus-server
}

"$@"
