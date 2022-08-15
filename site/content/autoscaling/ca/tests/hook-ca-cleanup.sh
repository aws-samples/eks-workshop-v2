before() {
  echo "noop"
}

after() {
  sleep 160

  num_nodes=$(kubectl get nodes -l workshop-default=yes -o json | jq -r '.items | length')

  if [[ $num_nodes -gt 3 ]]; then
    >&2 echo "Nodes did not scale down"
    exit 1
  fi
}

"$@"