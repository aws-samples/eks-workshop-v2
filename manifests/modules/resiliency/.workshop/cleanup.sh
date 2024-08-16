#!/bin/bash

set -e

echo "Starting cleanup process..."

# Function to safely delete a resource
safe_delete() {
    local cmd=$1
    local resource=$2
    echo "Attempting to delete $resource..."
    if $cmd 2>/dev/null; then
        echo "$resource deleted successfully."
    else
        echo "Failed to delete $resource or it doesn't exist. Continuing..."
    fi
}

# Function to wait for resource deletion
wait_for_deletion() {
    local check_cmd=$1
    local resource=$2
    local max_attempts=30
    local attempt=0
    echo "Waiting for $resource to be deleted..."
    while $check_cmd &>/dev/null && [ $attempt -lt $max_attempts ]; do
        sleep 10
        ((attempt++))
    done
    if [ $attempt -eq $max_attempts ]; then
        echo "Timeout waiting for $resource to be deleted."
    else
        echo "$resource deleted successfully."
    fi
}

# Function to cleanup EKS resources in a region
cleanup_eks_region() {
    local region=$1
    local cluster_name=$2
    local nodegroup_name=$3
    local delete_cluster=$4

    echo "Cleaning up EKS resources in $region..."

    # Switch to the specified region
    aws configure set default.region $region

    # Delete Kubernetes resources
    echo "Cleaning up Kubernetes resources..."
    kubectl delete ingress,deployment,service -n ui --all --ignore-not-found
    kubectl delete role,rolebinding -n ui --all --ignore-not-found
    kubectl delete namespace chaos-mesh --ignore-not-found

    # Delete EKS Cluster and Node Group if specified
    if [ "$delete_cluster" = true ]; then
        echo "Attempting to delete EKS cluster and node group..."
        if aws eks describe-cluster --name $cluster_name --region $region &>/dev/null; then
            aws eks delete-nodegroup --cluster-name $cluster_name --nodegroup-name $nodegroup_name --region $region || true
            wait_for_deletion "aws eks describe-nodegroup --cluster-name $cluster_name --nodegroup-name $nodegroup_name --region $region" "node group"
            
            aws eks delete-cluster --name $cluster_name --region $region
            wait_for_deletion "aws eks describe-cluster --name $cluster_name --region $region" "EKS cluster"
        else
            echo "EKS cluster $cluster_name not found in $region. Skipping deletion."
        fi
    else
        echo "Skipping EKS cluster and node group deletion in $region as requested."
    fi

    # Uninstall Helm charts
    echo "Uninstalling Helm charts..."
    helm uninstall aws-load-balancer-controller -n kube-system || true
    helm uninstall chaos-mesh -n chaos-mesh || true

    # Delete ALBs
    echo "Cleaning up ALBs in $region..."
    for alb_arn in $(aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s-ui-ui-') || starts_with(LoadBalancerName, 'k8s-default-ui-')].LoadBalancerArn" --output text); do
        safe_delete "aws elbv2 delete-load-balancer --load-balancer-arn $alb_arn" "ALB $alb_arn"
    done
}

# Cleanup in PRIMARY_REGION (preserve cluster and node groups)
cleanup_eks_region $PRIMARY_REGION "eks-workshop" "default" false

# Cleanup in SECONDARY_REGION (full cleanup)
cleanup_eks_region $SECONDARY_REGION "eks-workshop-east" "us-east-2-node-group" true

# Global cleanup (not region-specific)

# Delete IAM Roles and Policies
echo "Cleaning up IAM roles and policies..."
for role_prefix in "fis-execution-role-eks-workshop" "canary-execution-role-eks-workshop"; do
    for role in $(aws iam list-roles --query "Roles[?starts_with(RoleName, '${role_prefix}')].RoleName" --output text); do
        echo "Processing role: $role"
        for policy in $(aws iam list-attached-role-policies --role-name $role --query "AttachedPolicies[*].PolicyArn" --output text); do
            safe_delete "aws iam detach-role-policy --role-name $role --policy-arn $policy" "attached policy $policy from role $role"
        done
        for policy in $(aws iam list-role-policies --role-name $role --query "PolicyNames" --output text); do
            safe_delete "aws iam delete-role-policy --role-name $role --policy-name $policy" "inline policy $policy from role $role"
        done
        safe_delete "aws iam delete-role --role-name $role" "IAM role $role"
    done
done

for policy_prefix in "eks-resiliency-fis-policy" "eks-resiliency-canary-policy"; do
    for policy_arn in $(aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName, '${policy_prefix}')].Arn" --output text); do
        safe_delete "aws iam delete-policy --policy-arn $policy_arn" "IAM policy $policy_arn"
    done
done

# Delete S3 buckets
echo "Cleaning up S3 buckets..."
for bucket in $(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'eks-workshop-canary-artifacts-')].Name" --output text); do
    aws s3 rm s3://$bucket --recursive
    safe_delete "aws s3api delete-bucket --bucket $bucket --region $PRIMARY_REGION" "S3 bucket $bucket"
done

# Delete CloudWatch Synthetics canary and alarm
CANARY_NAME="eks-workshop-canary"
ALARM_NAME="eks-workshop-canary-alarm"

echo "Cleaning up CloudWatch Synthetics canary and alarm..."
if aws synthetics get-canary --name $CANARY_NAME --region $PRIMARY_REGION &>/dev/null; then
    aws synthetics stop-canary --name $CANARY_NAME --region $PRIMARY_REGION || true
    sleep 30
    safe_delete "aws synthetics delete-canary --name $CANARY_NAME --region $PRIMARY_REGION" "CloudWatch Synthetics canary $CANARY_NAME"
fi

safe_delete "aws cloudwatch delete-alarms --alarm-names $ALARM_NAME --region $PRIMARY_REGION" "CloudWatch alarm $ALARM_NAME"

echo "Cleanup process completed. Please check for any remaining resources manually."