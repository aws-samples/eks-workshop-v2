set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for condition=established --timeout=120s crd opentelemetrycollectors.opentelemetry.io
}

"$@"
