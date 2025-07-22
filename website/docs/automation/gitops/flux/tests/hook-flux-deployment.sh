set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 30
  
  kubectl wait --for=condition=Ready --timeout=60s pods -n ui
}

"$@"
