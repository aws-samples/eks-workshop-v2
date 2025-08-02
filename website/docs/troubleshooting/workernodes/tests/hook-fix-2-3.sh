set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  
  export node_output=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2)
  
  if [[ $node_output == *".internal"* ]]; then
 
    exit 0
  fi  
  # If we get here, it means we didn't find resources when we should have
  >&2 echo "Did not find any nodes when expecting a node"
  exit 1
}

"$@"
