set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10
  
  kubectl wait --for=condition=available --timeout=120s deployment/carts -n carts
}

"$@"
