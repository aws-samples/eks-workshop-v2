set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  kubectl wait --for=condition=Ready --timeout=30s pods -l app.kubernetes.io/component=aws-otel-collector-ci -n other
}

"$@"