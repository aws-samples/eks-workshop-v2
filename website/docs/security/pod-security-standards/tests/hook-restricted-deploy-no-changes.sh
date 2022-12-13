set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 5

  num_pods=$(kubectl -n assets  get pod -o json | jq -r '.items | length'  )
  
  if [[ $num_pods != 0 ]]; then
    >&2 echo "PSA labels were not added to the assets namespace"
    exit 1
  fi
}

"$@"
