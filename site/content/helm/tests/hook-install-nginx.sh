set -Eeuo pipefail

before() {
  # NONE
}

after() {
  kubectl wait --for=condition=available --timeout=60s deployment/mywebserver-nginx
}

"$@"