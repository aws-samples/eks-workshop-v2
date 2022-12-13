set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  reset-environment

  sleep 60

  kubectl delete -k /workspace/manifests --all

  sleep 60
}

"$@"
