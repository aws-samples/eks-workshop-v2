#!/bin/bash
# verify-cluster.sh - Verifies cluster state and corrects replica count

DESIRED_REPLICAS=5
MAX_WAIT_TIME=300  # 5 minutes
POLL_INTERVAL=10   # 10 seconds
NAMESPACE="ui"
EXPECTED_READY_NODES=3

print_header() {
    echo -e "\n==== $1 ====\n"
}

wait_for_condition() {
    local end_time=$((SECONDS + MAX_WAIT_TIME))
    while [ $SECONDS -lt $end_time ]; do
        if eval "$1"; then
            return 0
        fi
        echo -n "."
        sleep $POLL_INTERVAL
    done
    echo " Timeout!"
    return 1
}

print_header "Checking Current Pod Distribution"
timeout 5s $SCRIPT_DIR/get-pods-by-az.sh | head -n 30

print_header "Waiting for nodes to be Ready"
total_nodes=$(kubectl get nodes --no-headers | wc -l)
echo "Total nodes in the cluster: $total_nodes"
echo "Waiting for $EXPECTED_READY_NODES nodes to be in Ready state"
if wait_for_condition "[ \$(kubectl get nodes --no-headers | grep ' Ready ' | wc -l) -eq $EXPECTED_READY_NODES ]"; then
    echo -e "\n✅ $EXPECTED_READY_NODES nodes are in Ready state."
else
    echo -e "\n⚠️  Warning: $EXPECTED_READY_NODES nodes did not reach Ready state within the timeout period."
    exit 1
fi

print_header "Checking Current Pod Distribution"
timeout 5s $SCRIPT_DIR/get-pods-by-az.sh | head -n 30

print_header "Node Information"
kubectl get nodes -o wide

print_header "Verifying Cluster State"
node_count=$(kubectl get nodes --no-headers | grep " Ready " | grep -vc "SchedulingDisabled")
current_pod_count=$(kubectl get pods -n $NAMESPACE -l app=ui --no-headers | grep -v Terminating | wc -l)

echo "Ready and schedulable nodes: $node_count"
echo "Current active ui pods: $current_pod_count"
echo "Desired ui pods: $DESIRED_REPLICAS"

if [ $current_pod_count -ne $DESIRED_REPLICAS ]; then
    print_header "Adjusting Replica Count"
    echo "Scaling deployment to $DESIRED_REPLICAS replicas..."
    kubectl scale deployment ui -n $NAMESPACE --replicas=$DESIRED_REPLICAS

    echo -n "Waiting for pod count to stabilize"
    if wait_for_condition "[ \$(kubectl get pods -n $NAMESPACE -l app=ui --no-headers | grep -v Terminating | wc -l) -eq $DESIRED_REPLICAS ]"; then
        echo -e "\n✅ Pod count has reached the desired number."
    else
        echo -e "\n⚠️  Warning: Failed to reach desired pod count within the timeout period."
    fi
else
    echo "✅ Number of replicas is correct."
fi

print_header "Checking Pod Distribution"
if [ $node_count -gt 0 ]; then
    max_pods_per_node=$((DESIRED_REPLICAS / node_count + 1))
    uneven_distribution=false

    for node in $(kubectl get nodes -o name | grep -v "SchedulingDisabled"); do
        pods_on_node=$(kubectl get pods -n $NAMESPACE -l app=ui --field-selector spec.nodeName=${node#node/} --no-headers | grep -v Terminating | wc -l)
        if [ $pods_on_node -gt $max_pods_per_node ]; then
            uneven_distribution=true
            break
        fi
    done

    if $uneven_distribution; then
        echo "⚠️  Pod distribution is uneven. Rebalancing..."
        kubectl scale deployment ui -n $NAMESPACE --replicas=0
        sleep $POLL_INTERVAL
        kubectl scale deployment ui -n $NAMESPACE --replicas=$DESIRED_REPLICAS
        
        echo -n "Waiting for pods to be ready"
        if wait_for_condition "[ \$(kubectl get pods -n $NAMESPACE -l app=ui --no-headers | grep Running | wc -l) -eq $DESIRED_REPLICAS ]"; then
            echo -e "\n✅ Pods are ready and balanced."
        else
            echo -e "\n⚠️  Warning: Pods did not reach ready state within the timeout period."
        fi
    else
        echo "✅ Pod distribution is balanced."
    fi
else
    echo "⚠️  Warning: No Ready and schedulable nodes found. Cannot check pod distribution."
fi

print_header "Final Pod Distribution"
timeout 5s $SCRIPT_DIR/get-pods-by-az.sh | head -n 30

echo
if [ $node_count -gt 0 ] && [ $current_pod_count -eq $DESIRED_REPLICAS ]; then
    echo "✅ Cluster verification and correction complete."
else
    echo "⚠️  Cluster verification complete, but some issues may require attention."
fi