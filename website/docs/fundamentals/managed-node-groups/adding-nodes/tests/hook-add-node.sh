set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  num_nodes=$(kubectl get nodes -l workshop-default=yes -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 3 ]]; then
    >&2 echo "Nodes did not scale up"

    exit 1
  fi
}

"$@"
