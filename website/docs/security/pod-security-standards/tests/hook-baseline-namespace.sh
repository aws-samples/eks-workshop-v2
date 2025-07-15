set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  
  sleep 5

  num_labels=$(kubectl get ns nginx -ojson | jq -r '.metadata.labels | length')
  
  if [[ $num_labels != 5 ]]; then
    >&2 echo "PSA labels were not added to the nginx namespace"
    exit 1
  fi
}

"$@"
