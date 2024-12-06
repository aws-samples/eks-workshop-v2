set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  if kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1 2>&1 | grep -q "No resources found"; then
    echo "Success: No nodes found in nodegroup new_nodegroup_1 as expected"
    exit 0
  fi  

  >&2 echo "Found nodes in nodegroup new_nodegroup_1 when expecting 'No resources found'"
  exit 1
}



"$@"
