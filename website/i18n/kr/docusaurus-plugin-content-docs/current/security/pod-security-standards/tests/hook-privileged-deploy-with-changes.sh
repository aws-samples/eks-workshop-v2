set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 2

  kubectl rollout status -n assets deployment/assets --timeout 60s

  echo 'Rollout complete'

}

"$@"
