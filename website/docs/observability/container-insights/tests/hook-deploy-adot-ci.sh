set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  kubectl wait --for=condition=Ready --timeout=30s pods -l name=aws-otel-eks-ci -n other
}

"$@"