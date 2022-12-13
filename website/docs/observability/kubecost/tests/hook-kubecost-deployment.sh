set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10


  analyzer_success=$(kubectl rollout status deployment -n kubecost kubecost-cost-analyzer --timeout=60s)
  metrics_success=$(kubectl rollout status deployment -n kubecost kubecost-kube-state-metrics --timeout=60s)
  prometheus_success=$(kubectl rollout status deployment -n kubecost kubecost-prometheus-server --timeout=60s)

  if [[ $analyzer_success != "deployment \"kubecost-cost-analyzer\" successfully rolled out" ]]; then
    >&2 echo "Anaylyzer did not rollout"

    exit 1
  fi

    if [[ $metrics_success != "deployment \"kubecost-kube-state-metrics\" successfully rolled out" ]]; then
    >&2 echo "Metrics did not rollout"

    exit 1
  fi

    if [[ $prometheus_success != "deployment \"kubecost-prometheus-server\" successfully rolled out" ]]; then
    >&2 echo "Prometheus did not rollout"

    exit 1
  fi
}

"$@"
