set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl wait --for=condition=Ready --timeout=240s pods -l app.kubernetes.io/created-by=eks-workshop -A

  echo 'Rollout complete'

  kubectl get nodes -l workshop-default=yes

  num_nodes=$(kubectl get nodes -l workshop-default=yes -o json | jq -r '.items | length')

  if [[ $num_nodes -lt 3 ]]; then
    >&2 echo "Nodes did not scale up"

    exit 1
  fi
}

"$@"
