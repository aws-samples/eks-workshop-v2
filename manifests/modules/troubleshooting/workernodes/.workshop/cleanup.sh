# #!/bin/bash

# # Clean up any resources created by the user OUTSIDE of Terraform here

# # All stdout output will be hidden from the user
# # To display a message to the user:
# # logmessage "Deleting some resource...."


#!/bin/bash
set -e

# Function to force delete a namespace
force_delete_namespace() {
    local namespace=$1
    local max_attempts=3
    local attempt=1
    
    logmessage "Attempting to force delete namespace: $namespace"
    
    # First try normal deletion
    kubectl delete namespace $namespace --timeout=30s 2>/dev/null || true
    
    while kubectl get namespace $namespace >/dev/null 2>&1 && [ $attempt -le $max_attempts ]; do
        logmessage "Attempt $attempt to force delete namespace $namespace"
        
        # Get namespace json and remove finalizers
        kubectl get namespace $namespace -o json | jq '.spec.finalizers = []' > temp_ns.json
        
        # Trying different methods to remove the namespace
        if [ $attempt -eq 1 ]; then
            # First attempt: Try proxy method
            kubectl proxy --port=8001 >/dev/null 2>&1 &
            PROXY_PID=$!
            sleep 2
            curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp_ns.json http://127.0.0.1:8001/api/v1/namespaces/$namespace/finalize >/dev/null 2>&1 || true
            kill $PROXY_PID 2>/dev/null || true
            
        elif [ $attempt -eq 2 ]; then
            # Second attempt: Try direct API call
            kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f temp_ns.json >/dev/null 2>&1 || true
            
        else
            # Final attempt: Most aggressive approach
            logmessage "Using aggressive deletion approach..."
            kubectl get namespace $namespace -o json | jq '.metadata.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f - >/dev/null 2>&1 || true
            kubectl patch namespace $namespace -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        fi
        
        # Clean up temporary file
        rm -f temp_ns.json
        
        # Wait a bit before checking if namespace is gone
        sleep 5
        attempt=$((attempt + 1))
    done
    
    # Final check
    if kubectl get namespace $namespace >/dev/null 2>&1; then
        logmessage "WARNING: Namespace $namespace still exists after all deletion attempts"
        return 1
    else
        logmessage "Successfully deleted namespace $namespace"
        return 0
    fi
}

# Function to clean up namespace resources before deletion
cleanup_namespace_resources() {
    local namespace=$1
    
    logmessage "Cleaning up resources in namespace: $namespace"
    
    # Delete all resources that might block namespace deletion
    local resources=(
        "pods"
        "deployments"
        "daemonsets"
        "replicasets"
        "configmaps"
    )
    
    for resource in "${resources[@]}"; do
        logmessage "Forcing deletion of $resource in namespace $namespace"
        kubectl delete $resource --all -n $namespace --force --grace-period=0 2>/dev/null || true
    done
}

# Start AWS operations in parallel
logmessage "Starting parallel AWS resource cleanup..."

# Get instance IDs and start termination if any exist
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:eks:nodegroup-name,Values=new_nodegroup_3" \
             "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ ! -z "$INSTANCE_IDS" ]; then
    # Terminate instances and scale down nodegroup in parallel
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &
    aws eks update-nodegroup-config \
        --cluster-name $EKS_CLUSTER_NAME \
        --nodegroup-name new_nodegroup_3 \
        --scaling-config desiredSize=0,minSize=0,maxSize=1 &
fi

# Delete PriorityClass
kubectl delete priorityclass high-priority --force --grace-period=0 2>/dev/null || true

# Clean up prod namespace
if kubectl get namespace prod >/dev/null 2>&1; then
    logmessage "Cleaning up prod namespace..."
    cleanup_namespace_resources prod
    force_delete_namespace prod
fi

# Final nodegroup deletion
if aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
    logmessage "Deleting nodegroup..."
    aws eks delete-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_3
    
    timeout=180
    while [ $timeout -gt 0 ]; do
        if ! aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
            logmessage "Nodegroup deleted successfully."
            break
        fi
        logmessage "Waiting for nodegroup deletion... (${timeout}s remaining)"
        sleep 10
        timeout=$((timeout - 10))
    done
fi

# Delete launch template
logmessage "Deleting launch template..."
aws ec2 delete-launch-template --launch-template-name new_nodegroup_3 2>/dev/null || true

# Delete IAM role and policies
logmessage "Cleaning up IAM resources..."
aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null || true
aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly 2>/dev/null || true
aws iam delete-role --role-name new_nodegroup_3 2>/dev/null || true
logmessage "Cleanup complete."



