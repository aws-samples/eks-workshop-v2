#!/bin/bash

set -e

# Redefining Cluster Creator Cluster Admin Access
# Getting Cluster Creator Role from CloudFormation Stack
RESOURCE_ID=$(aws cloudformation list-stack-resources --stack-name workshop-stack --query 'StackResourceSummaries[?ResourceType==`AWS::IAM::Role`].LogicalResourceId' | awk -F '"' '/CodeBuildRole/{print$2}')

ROLE_NAME=$(aws cloudformation describe-stack-resource --stack-name workshop-stack --logical-resource-id $RESOURCE_ID --query 'StackResourceDetail.PhysicalResourceId' --output text)

# Getting Role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

# Granting Cluster Admin Access
aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster
