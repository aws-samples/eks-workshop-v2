set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

# Function to check node status
check_node_status() {
    local timeout=120  # 2 minutes
    local interval=10  # Check every 10 seconds
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        # Capture the output and redirect stderr to stdout
        node_status=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o wide 2>&1)
        
        # First check if any nodes exist
        if [[ -z "$node_status" ]] || echo "$node_status" | grep -q "No resources found"; then
            echo "No nodes found in nodegroup new_nodegroup_3"
            return 1
        fi

        # Get the node name if it exists
        NODE_NAME=$(echo "$node_status" | awk 'NR>1 {print $1}' | head -n1)
        
        if [ -z "$NODE_NAME" ]; then
            echo "Could not get node name from node status"
            echo "Current node status:"
            echo "$node_status"
            return 1
        fi

        echo "Found node: $NODE_NAME"

        # Check if there are any nodes in NotReady state
        if echo "$node_status" | grep -q "NotReady"; then
            echo "Success: Node in NotReady state found as expected"
            echo "Checking pods running on node $NODE_NAME:"
            if ! kubectl get pods --all-namespaces -o wide | grep -F "${NODE_NAME}" 2>/dev/null; then
                echo "No pods found running on node ${NODE_NAME}"
            fi
            return 0
        fi

        echo "Nodes found but not in NotReady state. Waiting... (${elapsed}s/${timeout}s)"
        echo "Current pods on node $NODE_NAME:"
        if ! kubectl get pods --all-namespaces -o wide | grep -F "${NODE_NAME}" 2>/dev/null; then
            echo "No pods found running on node ${NODE_NAME}"
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo "Timeout reached. Node did not transition to NotReady state within ${timeout} seconds"
    echo "Current node status:"
    echo "$node_status"
    if [ ! -z "$NODE_NAME" ]; then
        echo "Current pods on node $NODE_NAME:"
        if ! kubectl get pods --all-namespaces -o wide | grep -F "${NODE_NAME}" 2>/dev/null; then
            echo "No pods found running on node ${NODE_NAME}"
        fi
    fi
    return 1
}

# Call the function
check_node_status
status=$?

if [ $status -ne 0 ]; then
    echo "Node status check failed"
    exit 1
fi


  # # Capture the output and redirect stderr to stdout
  # node_status=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o wide 2>&1)
  
  # # Check if there are any nodes in NotReady state
  # if echo "$node_status" | grep -q "NotReady"; then
  #   echo "Success: Node in NotReady state found as expected"
  #   exit 0
  
  # fi

  # echo "expecting node in 'NotReady'. Found node in Ready or did not find any nodes in new_nodegroup_3"
  # exit 1
}

"$@"
