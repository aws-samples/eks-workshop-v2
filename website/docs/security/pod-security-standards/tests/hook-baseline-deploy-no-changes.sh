set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  
  sleep 5
  
  kubectl rollout status -n nginx deployment/nginx --timeout 60s

  echo 'Rollout complete'

}

"$@"
