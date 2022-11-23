set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl rollout status -n other deployment/pause-pods --timeout 300s

  echo 'Rollout complete'
}

"$@"
