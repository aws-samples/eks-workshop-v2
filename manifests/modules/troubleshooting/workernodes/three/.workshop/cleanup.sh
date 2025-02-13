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
    
    echo "Attempting to force delete namespace: $namespace"
    
    # First try normal deletion
    kubectl delete namespace $namespace --timeout=30s 2>/dev/null || true
    
    while kubectl get namespace $namespace >/dev/null 2>&1 && [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt to force delete namespace $namespace"
        
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
            echo "Using aggressive deletion approach..."
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
        echo "WARNING: Namespace $namespace still exists after all deletion attempts"
        return 1
    else
        echo "Successfully deleted namespace $namespace"
        return 0
    fi
}

# Function to clean up namespace resources before deletion
cleanup_namespace_resources() {
    local namespace=$1
    
    echo "Cleaning up resources in namespace: $namespace"
    
    # Delete all resources that might block namespace deletion
    local resources=(
        "pods"
        "deployments"
        "daemonsets"
        "replicasets"
        "configmaps"
    )
    
    for resource in "${resources[@]}"; do
        echo "Forcing deletion of $resource in namespace $namespace"
        kubectl delete $resource --all -n $namespace --force --grace-period=0 2>/dev/null || true
    done
}

# Start AWS operations in parallel
echo "Starting parallel AWS resource cleanup..."

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
        --cluster-name eks-workshop \
        --nodegroup-name new_nodegroup_3 \
        --scaling-config desiredSize=0,minSize=0,maxSize=1 &
fi

# Clean up metrics-server components
echo "Cleaning up metrics-server components..."
kubectl delete apiservice v1beta1.metrics.k8s.io --force --grace-period=0 2>/dev/null || true
kubectl delete -n kube-system serviceaccount metrics-server --force --grace-period=0 2>/dev/null || true
kubectl delete clusterrole system:aggregated-metrics-reader --force --grace-period=0 2>/dev/null || true
kubectl delete clusterrole system:metrics-server --force --grace-period=0 2>/dev/null || true
kubectl delete clusterrolebinding metrics-server:system:auth-delegator --force --grace-period=0 2>/dev/null || true
kubectl delete clusterrolebinding system:metrics-server --force --grace-period=0 2>/dev/null || true
kubectl delete -n kube-system service metrics-server --force --grace-period=0 2>/dev/null || true
kubectl delete -n kube-system deployment metrics-server --force --grace-period=0 2>/dev/null || true

# Delete helm release for metrics-server if it exists
helm uninstall metrics-server-custom -n kube-system 2>/dev/null || true

# Delete PriorityClass
kubectl delete priorityclass high-priority --force --grace-period=0 2>/dev/null || true

# Clean up prod namespace
if kubectl get namespace prod >/dev/null 2>&1; then
    echo "Cleaning up prod namespace..."
    cleanup_namespace_resources prod
    force_delete_namespace prod
fi

# Final nodegroup deletion
if aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
    echo "Deleting nodegroup..."
    aws eks delete-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3
    
    timeout=180
    while [ $timeout -gt 0 ]; do
        if ! aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
            echo "Nodegroup deleted successfully."
            break
        fi
        echo "Waiting for nodegroup deletion... (${timeout}s remaining)"
        sleep 10
        timeout=$((timeout - 10))
    done
fi

# Delete launch template
echo "Deleting launch template..."
aws ec2 delete-launch-template --launch-template-name new_nodegroup_3 2>/dev/null || true

# Delete IAM role and policies
echo "Cleaning up IAM resources..."
aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null || true
aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly 2>/dev/null || true
aws iam delete-role --role-name new_nodegroup_3 2>/dev/null || true

echo "Cleanup process completed. Please check for any remaining resources manually."




# #!/bin/bash
# set -e

# echo "Starting cleanup process..."

# # Function to delete k8s resources with force
# delete_k8s_resource() {
#     kubectl delete $1 $2 --force --grace-period=0 --timeout=30s 2>/dev/null || true
# }

# # Add specific cleanup for metrics-server components
# echo "Cleaning up metrics-server components..."
# kubectl delete apiservice v1beta1.metrics.k8s.io --force --grace-period=0 2>/dev/null || true
# kubectl delete -n kube-system serviceaccount metrics-server --force --grace-period=0 2>/dev/null || true
# kubectl delete clusterrole system:aggregated-metrics-reader --force --grace-period=0 2>/dev/null || true
# kubectl delete clusterrole system:metrics-server --force --grace-period=0 2>/dev/null || true
# kubectl delete clusterrolebinding metrics-server:system:auth-delegator --force --grace-period=0 2>/dev/null || true
# kubectl delete clusterrolebinding system:metrics-server --force --grace-period=0 2>/dev/null || true
# kubectl delete -n kube-system service metrics-server --force --grace-period=0 2>/dev/null || true
# kubectl delete -n kube-system deployment metrics-server --force --grace-period=0 2>/dev/null || true

# # Remove finalizers from namespaces
# kubectl get namespace prod -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/prod/finalize" -f - 2>/dev/null || true

# # Delete resources in prod
# kubectl delete pods,configmaps,deployments,daemonsets -n prod --all --force --grace-period=0

# # Delete namespaces and their contents in parallel
# kubectl delete namespace prod --force --grace-period=0 2>/dev/null &

# # Delete PriorityClass
# kubectl delete priorityclass high-priority --force --grace-period=0 2>/dev/null &

# # Delete helm release for metrics-server if it exists
# # helm uninstall metrics-server-custom -n kube-system 2>/dev/null &

# # Start AWS operations in parallel
# echo "Starting parallel AWS resource cleanup..."

# # Get instance IDs and start termination if any exist
# INSTANCE_IDS=$(aws ec2 describe-instances \
#     --filters "Name=tag:eks:nodegroup-name,Values=new_nodegroup_3" \
#              "Name=instance-state-name,Values=running,pending" \
#     --query 'Reservations[*].Instances[*].InstanceId' \
#     --output text)

# if [ ! -z "$INSTANCE_IDS" ]; then
#     # Terminate instances and scale down nodegroup in parallel
#     aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &
#     aws eks update-nodegroup-config \
#         --cluster-name eks-workshop \
#         --nodegroup-name new_nodegroup_3 \
#         --scaling-config desiredSize=0,minSize=0,maxSize=1 &
# fi

# # Wait for background jobs to complete
# # echo "Waiting for parallel operations to complete..."
# # wait

# # Quick check for any remaining pods in prod namespace
# if kubectl get namespace prod >/dev/null 2>&1; then
#     echo "Force deleting remaining pods and configmaps in prod namespace..."
#     kubectl delete pods,configmaps,deployments,daemonsets -n prod --all --force --grace-period=0 2>/dev/null || true
# fi

# # Final nodegroup deletion
# if aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
#     echo "Deleting nodegroup..."
#     aws eks delete-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3
    
#     timeout=180
#     while [ $timeout -gt 0 ]; do
#         if ! aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
#             echo "Nodegroup deleted successfully."
#             break
#         fi
#         echo "Waiting for nodegroup deletion... (${timeout}s remaining)"
#         sleep 10
#         timeout=$((timeout - 10))
#     done
# fi

# # Delete launch template
# echo "Deleting launch template..."
# aws ec2 delete-launch-template --launch-template-name new_nodegroup_3 2>/dev/null || true

# # Delete IAM role and policies
# echo "Cleaning up IAM resources..."
# aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null || true
# aws iam detach-role-policy --role-name new_nodegroup_3 --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly 2>/dev/null || true
# aws iam delete-role --role-name new_nodegroup_3 2>/dev/null || true

# echo "Cleanup process completed. Please check for any remaining resources manually."



# #!/bin/bash
# set -e

# echo "Starting cleanup process..."

# # Function to delete k8s resources with force
# delete_k8s_resource() {
#     kubectl delete $1 $2 --force --grace-period=0 --timeout=30s 2>/dev/null || true
# }

# # Function to wait for resource deletion
# wait_for_deletion() {
#     local resource_type=$1
#     local resource_name=$2
#     local namespace=$3
#     local timeout=30
    
#     while [ $timeout -gt 0 ] && kubectl get $resource_type $resource_name ${namespace:+-n $namespace} >/dev/null 2>&1; do
#         sleep 2
#         timeout=$((timeout - 2))
#     done
# }

# # Delete kubernetes resources in parallel
# echo "Starting parallel kubernetes resource deletion..."

# # Remove finalizers from namespaces (added)
# kubectl get namespace prod -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/prod/finalize" -f - 2>/dev/null || true &
# # kubectl get namespace amazon-cloudwatch -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/amazon-cloudwatch/finalize" -f - 2>/dev/null || true &

# # Delete namespaces and their contents in parallel
# kubectl delete namespace prod --force --grace-period=0 2>/dev/null &
# # kubectl delete namespace amazon-cloudwatch --force --grace-period=0 2>/dev/null &
# kubectl delete priorityclass high-priority --force --grace-period=0 2>/dev/null &

# # Delete helm releases in background (added metrics-server-custom)
# helm uninstall metrics-server-custom -n kube-system 2>/dev/null &
# # helm uninstall aws-cloudwatch-metrics -n amazon-cloudwatch 2>/dev/null &

# # Delete specific ConfigMap (added)
# kubectl delete configmap aws-cloudwatch-metrics -n amazon-cloudwatch --force --grace-period=0 2>/dev/null &

# # Start AWS operations in parallel
# echo "Starting parallel AWS resource cleanup..."

# # Get instance IDs and start termination if any exist
# INSTANCE_IDS=$(aws ec2 describe-instances \
#     --filters "Name=tag:eks:nodegroup-name,Values=new_nodegroup_3" \
#              "Name=instance-state-name,Values=running,pending" \
#     --query 'Reservations[*].Instances[*].InstanceId' \
#     --output text)

# if [ ! -z "$INSTANCE_IDS" ]; then
#     # Terminate instances and scale down nodegroup in parallel
#     aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &
#     aws eks update-nodegroup-config \
#         --cluster-name eks-workshop \
#         --nodegroup-name new_nodegroup_3 \
#         --scaling-config desiredSize=0,minSize=0,maxSize=1 &
# fi

# # Wait for background jobs to complete
# echo "Waiting for parallel operations to complete..."
# wait

# # Quick check for any remaining pods in critical namespaces
# for ns in prod amazon-cloudwatch; do
#     if kubectl get namespace $ns >/dev/null 2>&1; then
#         echo "Force deleting remaining pods in $ns namespace..."
#         # Added configmaps to deletion
#         kubectl delete pods,configmaps -n $ns --all --force --grace-period=0 2>/dev/null || true
#     fi
# done

# # Final nodegroup deletion
# if aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
#     echo "Deleting nodegroup..."
#     aws eks delete-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3
    
#     # Reduced wait time with status checks
#     timeout=180
#     while [ $timeout -gt 0 ]; do
#         if ! aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 >/dev/null 2>&1; then
#             echo "Nodegroup deleted successfully."
#             break
#         fi
#         echo "Waiting for nodegroup deletion... (${timeout}s remaining)"
#         sleep 10
#         timeout=$((timeout - 10))
#     done
# fi

# echo "Cleanup process completed. Please check for any remaining resources manually."





# #Delete new deployment and daemonsets.  new_nodegroup_3, launch template and role



# #!/bin/bash

# # Set error handling
# set -e

# echo "Starting cleanup process..."

# # Function to check if kubectl resource exists
# check_k8s_resource() {
#     local resource_type=$1
#     local resource_name=$2
#     kubectl get ${resource_type} ${resource_name} -n default --ignore-not-found
# }

# # Function to check if AWS resource exists
# check_aws_resource() {
#     local command=$1
#     local resource_name=$2
#     eval "${command}" 2>/dev/null || echo "Not found"
# }

# # 1. Check and delete DaemonSet and Deployment
# # 1. Check and delete DaemonSet and Deployment
# echo "Checking for prod-ds DaemonSet..."
# if [[ $(check_k8s_resource daemonset prod-ds) ]]; then
#     echo "Deleting prod-ds DaemonSet..."
#     # First attempt normal deletion
#     kubectl delete daemonset prod-ds -n default --timeout=30s

#     # Check if daemonset still exists
#     if [[ $(check_k8s_resource daemonset prod-ds) ]]; then
#         echo "DaemonSet still exists, attempting force deletion..."
#         # Force delete the pods first
#         PROD_DS_PODS=$(kubectl get pods -n default -l name=prod-ds -o name 2>/dev/null)
#         if [ ! -z "$PROD_DS_PODS" ]; then
#             echo "Force deleting prod-ds pods..."
#             kubectl delete pods -n default -l name=prod-ds --grace-period=0 --force
            
#             # Wait for pods to be deleted
#             timeout=30
#             while [ $timeout -gt 0 ] && kubectl get pods -n default -l name=prod-ds 2>/dev/null | grep -q .; do
#                 echo "Waiting for pods to be forcefully terminated... (${timeout}s remaining)"
#                 sleep 5
#                 timeout=$((timeout - 5))
#             done
#         fi

#         # Try deleting the daemonset again
#         kubectl delete daemonset prod-ds -n default --grace-period=0 --force
        
#         if [[ $(check_k8s_resource daemonset prod-ds) ]]; then
#             echo "WARNING: prod-ds DaemonSet still exists. Please check and delete manually."
#         else
#             echo "prod-ds DaemonSet force deleted successfully."
#         fi
#     else
#         echo "prod-ds DaemonSet deleted successfully."
#     fi
# else
#     echo "prod-ds DaemonSet not found."
# fi


# echo "Checking for prod-app Deployment..."
# if [[ $(check_k8s_resource deployment prod-app) ]]; then
#     echo "Deleting prod-app Deployment..."
#     kubectl delete deployment prod-app -n default
#     if [[ $(check_k8s_resource deployment prod-app) ]]; then
#         echo "WARNING: prod-app Deployment still exists. Please check and delete manually."
#     else
#         echo "prod-app Deployment deleted successfully."
#     fi
# else
#     echo "prod-app Deployment not found."
# fi

# # Delete amazon-cloudwatch resources
# echo "Checking for amazon-cloudwatch namespace and resources..."
# if [[ $(kubectl get namespace amazon-cloudwatch --ignore-not-found) ]]; then
#     echo "Found amazon-cloudwatch namespace. Deleting helm release..."
    
#     # Delete the helm release first
#     if helm list -n amazon-cloudwatch | grep -q "aws-cloudwatch-metrics"; then
#         echo "Deleting aws-cloudwatch-metrics helm release..."
#         helm uninstall aws-cloudwatch-metrics -n amazon-cloudwatch
        
#         # Wait for helm release to be completely removed
#         timeout=60
#         while [ $timeout -gt 0 ] && helm list -n amazon-cloudwatch | grep -q "aws-cloudwatch-metrics"; do
#             echo "Waiting for helm release to be deleted... (${timeout}s remaining)"
#             sleep 5
#             timeout=$((timeout - 5))
#         done
#     else
#         echo "aws-cloudwatch-metrics helm release not found"
#     fi

#     # Force delete any remaining cloudwatch pods
#     echo "Force deleting any remaining cloudwatch pods..."
#     CLOUDWATCH_PODS=$(kubectl get pods -n amazon-cloudwatch -o name 2>/dev/null)
#     if [ ! -z "$CLOUDWATCH_PODS" ]; then
#         echo "Found cloudwatch pods, force deleting..."
#         kubectl delete pods -n amazon-cloudwatch --all --grace-period=0 --force
        
#         # Wait for pods to be deleted
#         timeout=30
#         while [ $timeout -gt 0 ] && kubectl get pods -n amazon-cloudwatch 2>/dev/null | grep -q .; do
#             echo "Waiting for pods to be forcefully terminated... (${timeout}s remaining)"
#             sleep 5
#             timeout=$((timeout - 5))
#         done

#         if kubectl get pods -n amazon-cloudwatch 2>/dev/null | grep -q .; then
#             echo "WARNING: Some pods still exist in amazon-cloudwatch namespace. Will proceed with namespace deletion anyway."
#         else
#             echo "All cloudwatch pods successfully terminated."
#         fi
#     else
#         echo "No cloudwatch pods found."
#     fi


#     echo "Deleting amazon-cloudwatch namespace..."
#     kubectl delete namespace amazon-cloudwatch --timeout=60s
    
#     # Wait for namespace deletion
#     timeout=60
#     while [ $timeout -gt 0 ] && kubectl get namespace amazon-cloudwatch >/dev/null 2>&1; do
#         echo "Waiting for namespace deletion... (${timeout}s remaining)"
#         sleep 5
#         timeout=$((timeout - 5))
#     done

#     if kubectl get namespace amazon-cloudwatch >/dev/null 2>&1; then
#         echo "WARNING: amazon-cloudwatch namespace still exists. Please check and delete manually."
#     else
#         echo "amazon-cloudwatch namespace deleted successfully."
#     fi
# else
#     echo "amazon-cloudwatch namespace not found."
# fi

# # Delete kubernetes priority class
# echo "Checking for high-priority PriorityClass..."
# if [[ $(kubectl get priorityclass high-priority --ignore-not-found) ]]; then
#     echo "Deleting high-priority PriorityClass..."
#     kubectl delete priorityclass high-priority
    
#     # Wait for priority class deletion
#     timeout=30
#     while [ $timeout -gt 0 ] && kubectl get priorityclass high-priority >/dev/null 2>&1; do
#         echo "Waiting for priority class deletion... (${timeout}s remaining)"
#         sleep 5
#         timeout=$((timeout - 5))
#     done

#     if kubectl get priorityclass high-priority >/dev/null 2>&1; then
#         echo "WARNING: high-priority PriorityClass still exists. Please check and delete manually."
#     else
#         echo "high-priority PriorityClass deleted successfully."
#     fi
# else
#     echo "high-priority PriorityClass not found."
# fi

# # Delete prod namespace
# echo "Checking for prod namespace..."
# if [[ $(kubectl get namespace prod --ignore-not-found) ]]; then
#     echo "Deleting prod namespace..."
#     kubectl delete namespace prod --timeout=60s
    
#     # Wait for namespace deletion
#     timeout=60
#     while [ $timeout -gt 0 ] && kubectl get namespace prod >/dev/null 2>&1; do
#         echo "Waiting for namespace deletion... (${timeout}s remaining)"
#         sleep 5
#         timeout=$((timeout - 5))
#     done

#     if kubectl get namespace prod >/dev/null 2>&1; then
#         echo "WARNING: prod namespace still exists. Please check and delete manually."
#     else
#         echo "prod namespace deleted successfully."
#     fi
# else
#     echo "prod namespace not found."
# fi


# # 2. Check for nodegroup then scale down and delete if exists
# echo "Checking for new_nodegroup_3 NodeGroup..."
# if [[ $(aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 2>/dev/null) ]]; then
#     echo "Checking for existing nodes in new_nodegroup_3..."
    
#     # Get instance IDs of nodes in the nodegroup
#     INSTANCE_IDS=$(aws ec2 describe-instances \
#         --filters "Name=tag:eks:nodegroup-name,Values=new_nodegroup_3" \
#                  "Name=instance-state-name,Values=running,pending" \
#         --query 'Reservations[*].Instances[*].InstanceId' \
#         --output text)
    
#     if [ ! -z "$INSTANCE_IDS" ]; then
#         echo "Found instances in nodegroup. Starting parallel termination and scale down..."
        
#         # Function to handle instance termination
#         terminate_instances() {
#             echo "Terminating instances..."
#             aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
            
#             timeout=300  # 5 minutes
#             while [ $timeout -gt 0 ]; do
#                 PENDING_TERMINATION=$(aws ec2 describe-instances \
#                     --instance-ids $INSTANCE_IDS \
#                     --query 'Reservations[*].Instances[*].State.Name' \
#                     --output text | grep -E 'running|pending|shutting-down' || echo "")
                
#                 if [ -z "$PENDING_TERMINATION" ]; then
#                     echo "All instances successfully terminated."
#                     return 0
#                 fi
#                 echo "Waiting for instances to terminate... (${timeout}s remaining)"
#                 sleep 10
#                 timeout=$((timeout - 10))
#             done

#             if [ $timeout -le 0 ]; then
#                 echo "WARNING: Timeout reached while waiting for instances to terminate."
#                 return 1
#             fi
#         }

#         # Function to handle nodegroup scale down
#         scale_down_nodegroup() {
#             echo "Scaling down nodegroup to 0..."
#             aws eks update-nodegroup-config \
#                 --cluster-name eks-workshop \
#                 --nodegroup-name new_nodegroup_3 \
#                 --scaling-config desiredSize=0,minSize=0,maxSize=1

#             timeout=60  # 1 minute
#             while [ $timeout -gt 0 ]; do
#                 DESIRED_SIZE=$(aws eks describe-nodegroup \
#                     --cluster-name eks-workshop \
#                     --nodegroup-name new_nodegroup_3 \
#                     --query 'nodegroup.scalingConfig.desiredSize' \
#                     --output text)
                
#                 if [ "$DESIRED_SIZE" -eq 0 ]; then
#                     echo "Nodegroup successfully scaled down to 0."
#                     return 0
#                 fi
#                 echo "Waiting for nodegroup scale down... (${timeout}s remaining)"
#                 sleep 10
#                 timeout=$((timeout - 10))
#             done

#             if [ $timeout -le 0 ]; then
#                 echo "WARNING: Timeout reached while waiting for nodegroup scale down."
#                 return 1
#             fi
#         }

#         # Run both operations in parallel
#         terminate_instances &
#         TERMINATE_PID=$!
        
#         scale_down_nodegroup &
#         SCALE_PID=$!

#         # Wait for both processes to complete
#         wait $TERMINATE_PID
#         TERMINATE_STATUS=$?
        
#         wait $SCALE_PID
#         SCALE_STATUS=$?

#         # Check if both operations were successful
#         if [ $TERMINATE_STATUS -ne 0 ] || [ $SCALE_STATUS -ne 0 ]; then
#             echo "ERROR: One or more operations failed."
#             echo "Termination status: $TERMINATE_STATUS"
#             echo "Scale down status: $SCALE_STATUS"
#             exit 1
#         fi

#         echo "Both instance termination and nodegroup scale down completed successfully."
#     else
#         echo "No running instances found in nodegroup."
#     fi

#     # Delete the nodegroup
#     echo "Deleting new_nodegroup_3 NodeGroup..."
#     aws eks delete-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3
    
#     echo "Waiting for NodeGroup deletion to complete..."
#     aws eks wait nodegroup-deleted --cluster-name eks-workshop --nodegroup-name new_nodegroup_3
    
#     if [[ $(aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_3 2>/dev/null) ]]; then
#         echo "WARNING: new_nodegroup_3 NodeGroup still exists. Please check and delete manually."
#         exit 1
#     else
#         echo "new_nodegroup_3 NodeGroup deleted successfully."
#     fi
# else
#     echo "new_nodegroup_3 NodeGroup not found."
# fi


# echo "Cleanup process completed. Please review any warnings above and take manual action if needed."
