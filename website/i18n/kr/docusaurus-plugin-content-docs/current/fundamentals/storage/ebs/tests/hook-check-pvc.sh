set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  num_pvcs=$(kubectl get pvc -n catalog -o json | jq -r '.items | length')

  if [[ $num_pvcs -lt 1 ]]; then
    >&2 echo "PVC not provisioned"

    exit 1
  fi
}

"$@"
