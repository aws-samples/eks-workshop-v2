set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl rollout status -n ui deployment/ui --timeout 120s

  echo 'Rollout complete'

  pending_pods=$(kubectl -n other get pod -l run=pause-pods --field-selector=status.phase=Pending -o json | jq -r '.items | length')

  if [[ $pending_pods -lt 1 ]]; then
    >&2 echo "Some pause pods should be pending"

    exit 1
  fi
}

"$@"