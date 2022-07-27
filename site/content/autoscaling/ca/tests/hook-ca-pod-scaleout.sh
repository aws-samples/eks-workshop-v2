set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait pods -n default -l app=nginx --for condition=Ready --timeout=180s

  num_nodes=$(kubectl get nodes -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 4 ]]; then
    >&2 echo "Nodes did not scale up"
    exit 1
  fi
}

"$@"