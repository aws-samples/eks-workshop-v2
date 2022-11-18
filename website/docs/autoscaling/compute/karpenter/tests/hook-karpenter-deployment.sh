set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  num_nodes=$(kubectl get nodes --selector=type=karpenter -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 1 ]]; then
    >&2 echo "Nodes did not scale up"
    exit 1
  fi
}

"$@"
