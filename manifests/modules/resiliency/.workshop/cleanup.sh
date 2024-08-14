#!/bin/bash

set -e

# Delete Ingress
kubectl delete ingress -n ui ui --ignore-not-found
kubectl delete ingress ui -n ui --ignore-not-found

# Delete Deployments
kubectl delete deployment -n ui ui --ignore-not-found
kubectl delete deployment ui -n ui --ignore-not-found

# Delete Services
kubectl delete service -n ui ui-nlb --ignore-not-found

# Delete Roles and RoleBindings
kubectl delete role chaos-mesh-role -n ui --ignore-not-found
kubectl delete rolebinding chaos-mesh-rolebinding -n ui --ignore-not-found

# Uninstall Helm chart
if command -v helm &> /dev/null; then
    echo "Uninstalling aws-load-balancer-controller Helm chart"
    helm uninstall aws-load-balancer-controller -n kube-system || true
    
    echo "Uninstalling Chaos Mesh Helm chart"
    helm uninstall chaos-mesh -n chaos-mesh || true
    
    # Wait for resources to be cleaned up
    echo "Waiting for resources to be cleaned up..."
    sleep 30
else
    echo "Helm command not found. Skipping Helm chart uninstallations."
fi

kubectl delete namespace chaos-mesh --ignore-not-found

# Delete IAM Roles and Policies
ROLE_PREFIX="fis-execution-role-eks-workshop"
POLICY_PREFIX="eks-resiliency-fis-policy"

# List and delete roles
for role in $(aws iam list-roles --query "Roles[?starts_with(RoleName, '${ROLE_PREFIX}')].RoleName" --output text); do
    echo "Detaching policies and deleting role: $role"
    # Detach managed policies
    aws iam detach-role-policy --role-name $role --policy-arn arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorEKSAccess || true
    aws iam detach-role-policy --role-name $role --policy-arn arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorNetworkAccess || true
    
    # Detach and delete inline policies
    for policy in $(aws iam list-role-policies --role-name $role --query PolicyNames --output text); do
        aws iam delete-role-policy --role-name $role --policy-name $policy || true
    done
    
    # Delete the role
    aws iam delete-role --role-name $role || true
done

# List and delete policies
for policy_arn in $(aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName, '${POLICY_PREFIX}')].Arn" --output text); do
    echo "Deleting policy: $policy_arn"
    
    # Detach policy from all attached roles
    for role in $(aws iam list-entities-for-policy --policy-arn $policy_arn --entity-filter Role --query 'PolicyRoles[*].RoleName' --output text); do
        aws iam detach-role-policy --role-name $role --policy-arn $policy_arn
    done
    
    # Delete the policy
    aws iam delete-policy --policy-arn $policy_arn
done

# Delete any leftover ALBs
ALB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s-ui-ui-') || starts_with(LoadBalancerName, 'k8s-default-ui-')].LoadBalancerArn" --output text)
if [ ! -z "$ALB_ARN" ]; then
    echo "Deleting leftover ALB: $ALB_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
else
    echo "No leftover ALB found."
fi

# Delete S3 bucket
BUCKET_PREFIX="eks-workshop-canary-artifacts-"
for bucket in $(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${BUCKET_PREFIX}')].Name" --output text); do
    echo "Deleting S3 bucket: $bucket"
    # First, remove all objects from the bucket
    aws s3 rm s3://$bucket --recursive
    # Then delete the bucket
    aws s3api delete-bucket --bucket $bucket --region us-west-2
done

# Delete CloudWatch Synthetics canary
CANARY_NAME="eks-workshop-canary"
if aws synthetics get-canary --name $CANARY_NAME --region us-west-2 &> /dev/null; then
    echo "Deleting CloudWatch Synthetics canary: $CANARY_NAME"
    aws synthetics delete-canary --name $CANARY_NAME --region us-west-2
else
    echo "CloudWatch Synthetics canary $CANARY_NAME not found."
fi

echo "Cleanup completed successfully."