set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A

  echo 'Rollout complete'

  pending_pods=$(kubectl -n other get pod -l run=pause-pods --field-selector=status.phase=Pending -o json | jq -r '.items | length')

  if [[ $pending_pods -lt 1 ]]; then
    >&2 echo "Some pause pods should be pending"

    exit 1
  fi
}

"$@"
