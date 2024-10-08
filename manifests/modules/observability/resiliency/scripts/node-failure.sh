#!/bin/bash
# node-failure.sh - Simulates node failure by stopping an EC2 instance with running pods

# Get a list of nodes with running pods
node_with_pods=$(kubectl get pods --all-namespaces -o wide | awk 'NR>1 {print $8}' | sort | uniq)

if [ -z "$node_with_pods" ]; then
    echo "No nodes with running pods found. Please run this script: $SCRIPT_DIR/verify-cluster.sh"
    exit 1
fi

# Select a random node from the list
selected_node=$(echo "$node_with_pods" | shuf -n 1)

# Get the EC2 instance ID for the selected node
instance_id=$(aws ec2 describe-instances \
    --filters "Name=private-dns-name,Values=$selected_node" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

# Stop the instance to simulate a node failure
echo "Stopping instance: $instance_id (Node: $selected_node)"
aws ec2 stop-instances --instance-ids $instance_id

echo "Instance $instance_id is being stopped. Monitoring pod distribution..."
