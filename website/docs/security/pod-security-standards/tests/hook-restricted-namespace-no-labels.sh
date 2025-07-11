set -Eeuo pipefail

before() {
  sleep 2
  echo "noop"
}

after() {
  sleep 5

  num_labels=$(kubectl get ns nginx -ojson | jq -r '.metadata.labels | length')
  
  if [[ $num_labels != 2 ]]; then
    >&2 echo "There should not be any PSA labels added initially to the nginx namespace"
    exit 1
  fi
}

"$@"
