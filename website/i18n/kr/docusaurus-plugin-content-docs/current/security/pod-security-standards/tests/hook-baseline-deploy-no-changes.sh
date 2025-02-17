set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  
  sleep 5
  
  kubectl rollout status -n assets deployment/assets --timeout 60s

  echo 'Rollout complete'

}

"$@"
