set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 2

  kubectl rollout status -n nginx deployment/nginx --timeout 60s

  echo 'Rollout complete'

}

"$@"
