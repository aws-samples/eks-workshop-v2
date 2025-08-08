#!/bin/bash

set -e

logmessage "Deleting failing pod..."

kubectl delete -f /eks-workshop/manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml --ignore-not-found

POD_ASSOCIATION_ID=$(aws eks list-pod-identity-associations --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --service-account carts --namespace carts --output text --query 'associations[0].associationId')

if [ "$POD_ASSOCIATION_ID" != "None" ]; then
  logmessage "Deleting EKS Pod Identity Association..."
  
  aws eks delete-pod-identity-association --region $AWS_REGION --association-id $POD_ASSOCIATION_ID --cluster-name $EKS_CLUSTER_NAME

fi

check=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION --query "addons[? @ == 'eks-pod-identity-agent']" --output text)

if [ ! -z "$check" ]; then
  logmessage "Deleting EKS Pod Identity Agent addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --region $AWS_REGION
fi

# Check if the carts-pod-identity role exists and delete it
ROLE_NAME="${EKS_CLUSTER_NAME}-carts-dynamo"
ROLE_EXISTS=$(aws iam get-role --role-name $ROLE_NAME --region $AWS_REGION --query 'Role.RoleName' --output text 2>/dev/null || echo "None")

if [ "$ROLE_EXISTS" != "None" ]; then
  logmessage "Deleting IAM role: $ROLE_NAME..."
  
  # First, detach any attached policies
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE_NAME --region $AWS_REGION --query 'AttachedPolicies[].PolicyArn' --output text)
  
  if [ ! -z "$ATTACHED_POLICIES" ]; then
    for policy_arn in $ATTACHED_POLICIES; do
      logmessage "Detaching policy: $policy_arn from role: $ROLE_NAME"
      aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $policy_arn --region $AWS_REGION
    done
  fi
  
  # Delete any inline policies
  INLINE_POLICIES=$(aws iam list-role-policies --role-name $ROLE_NAME --region $AWS_REGION --query 'PolicyNames' --output text)
  
  if [ ! -z "$INLINE_POLICIES" ]; then
    for policy_name in $INLINE_POLICIES; do
      logmessage "Deleting inline policy: $policy_name from role: $ROLE_NAME"
      aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $policy_name --region $AWS_REGION
    done
  fi
  
  # Finally, delete the role
  aws iam delete-role --role-name $ROLE_NAME --region $AWS_REGION
  logmessage "Successfully deleted IAM role: $ROLE_NAME"
fi

