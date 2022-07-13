set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for=condition=available --timeout=180s deployment/nginx-to-scaleout

  num_nodes=$(kubectl get nodes -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 4 ]]; then
    >&2 echo "Nodes did not scale up"
    exit 1
  fi
}

"$@"