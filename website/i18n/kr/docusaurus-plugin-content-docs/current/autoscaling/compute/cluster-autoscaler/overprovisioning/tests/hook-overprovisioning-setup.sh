set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl rollout status -n other deployment/pause-pods --timeout 300s

  echo 'Rollout complete'

  kubectl get nodes -l workshop-default=yes

  num_nodes=$(kubectl get nodes -l workshop-default=yes -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 6 ]]; then
    >&2 echo "Nodes did not scale up"

    exit 1
  fi
}

"$@"
