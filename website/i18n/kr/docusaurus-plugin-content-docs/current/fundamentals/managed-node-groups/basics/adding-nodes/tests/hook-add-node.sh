set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  num_nodes=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=$EKS_DEFAULT_MNG_NAME -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 4 ]]; then
    >&2 echo "Nodes did not scale up"

    exit 1
  fi
}

"$@"
