set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Give HPA time to scale out
  sleep 120

  num_pods=$(kubectl get pod -l app=php-apache -o json | jq -r '.items | length')

  if [[ $num_pods -lt 2 ]]; then
    >&2 echo "Pods did not scale up"
    exit 1
  fi
}

"$@"
