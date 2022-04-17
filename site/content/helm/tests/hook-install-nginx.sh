set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for=condition=available --timeout=60s deployment/mywebserver-nginx
}

"$@"