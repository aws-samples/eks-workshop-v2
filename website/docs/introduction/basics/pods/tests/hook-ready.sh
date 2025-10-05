set -Eeuo pipefail

before() {
  kubectl wait --for=condition=Ready --timeout=60s -n ui pod/ui-pod
}

after() {
  echo "noop"
}

"$@"
