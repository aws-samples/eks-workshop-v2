set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  # Capture the output and redirect stderr to stdout
  node_status=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o wide 2>&1)
  
  # Check if there are any nodes in NotReady state
  if echo "$node_status" | grep -q "NotReady"; then
    echo "Success: Node in NotReady state found as expected"
    exit 0
  fi

  echo "expecting node in 'NotReady'. Found node in Ready or did not find any nodes in new_nodegroup_3"
  exit 1
}

"$@"
