set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  replicas=$(kubectl get deployment/kubecost-cost-analyzer -n kubecost -o json | jq -r '.status.availableReplicas')

  if [[ $replicas -lt 1 ]]; then
    >&2 echo "No replicas"

    exit 1
  fi
}

"$@"