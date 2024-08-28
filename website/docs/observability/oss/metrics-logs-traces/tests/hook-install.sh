set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for condition=established --timeout=120s crd opentelemetrycollectors.opentelemetry.io
  kubectl wait --for condition=available --timeout=120s -n opentelemetry-operator-system deployment opentelemetry-operator
  kubectl wait --for condition=established --timeout=120s crd grafanas.grafana.integreatly.org
  kubectl wait --for condition=available --timeout=120s -n grafana-operator-system deployment grafana-operator
  kubectl wait --for condition=available --timeout=120s -n grafana deployment grafana-deployment
  kubectl wait --for condition=ready --timeout=120s -n loki-system pod loki-0
  kubectl wait --for condition=ready --timeout=120s -n tempo-system pod tempo-0
}

"$@"
