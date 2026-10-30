#!/bin/bash

set -e

# The lab enables Container Insights by installing the amazon-cloudwatch-observability
# add-on and wiring an IAM role to the cloudwatch-agent service account via EKS Pod
# Identity. The EKS Pod Identity Agent add-on and the CloudWatch dashboard are managed by
# Terraform and torn down by prepare-environment, so here we only remove what the lab
# steps created.

logmessage "Deleting the Amazon CloudWatch Observability add-on..."

aws eks delete-addon \
  --cluster-name "$EKS_CLUSTER_NAME" \
  --addon-name amazon-cloudwatch-observability 2>/dev/null || true
aws eks wait addon-deleted \
  --cluster-name "$EKS_CLUSTER_NAME" \
  --addon-name amazon-cloudwatch-observability 2>/dev/null || true

logmessage "Deleting the CloudWatch agent Pod Identity association..."

association_id=$(aws eks list-pod-identity-associations \
  --cluster-name "$EKS_CLUSTER_NAME" \
  --namespace amazon-cloudwatch \
  --service-account cloudwatch-agent \
  --query 'associations[0].associationId' --output text 2>/dev/null || echo "None")

if [ "$association_id" != "None" ] && [ -n "$association_id" ]; then
  aws eks delete-pod-identity-association \
    --cluster-name "$EKS_CLUSTER_NAME" \
    --association-id "$association_id" 2>/dev/null || true
fi

logmessage "Deleting the CloudWatch agent IAM role..."

role_name="$EKS_CLUSTER_NAME-cloudwatch-agent"
if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
  aws iam detach-role-policy \
    --role-name "$role_name" \
    --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy 2>/dev/null || true
  aws iam delete-role --role-name "$role_name" 2>/dev/null || true
fi

kubectl delete -n other pod load-generator --ignore-not-found
