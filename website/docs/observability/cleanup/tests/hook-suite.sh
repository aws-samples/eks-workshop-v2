set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  prepare-environment

  sleep 60

  kubectl delete -k /manifests/base --all

  sleep 60
}

"$@"
