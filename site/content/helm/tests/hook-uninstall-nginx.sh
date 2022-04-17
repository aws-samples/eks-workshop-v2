set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait "pod" --for=delete --timeout=60s --selector app.kubernetes.io/name=nginx
}

"$@"