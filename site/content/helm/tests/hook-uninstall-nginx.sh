set -Eeuo pipefail

before() {
  # NONE
}

after() {
  kubectl wait "pod" --for=delete --timeout=60s --selector app.kubernetes.io/name=nginx
}

"$@"