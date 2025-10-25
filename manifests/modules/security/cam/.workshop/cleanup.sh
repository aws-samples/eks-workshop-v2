#!/bin/bash

set -e

logmessage "Cleaning up cluster access entries..."

kubectl delete -k ~/environment/eks-workshop/modules/security/cam/rbac --ignore-not-found

read_only_check=$(aws eks list-access-entries --cluster-name $EKS_CLUSTER_NAME --output text | grep $READ_ONLY_IAM_ROLE || true)

if [ ! -z "$read_only_check" ]; then
  aws eks delete-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
fi

carts_check=$(aws eks list-access-entries --cluster-name $EKS_CLUSTER_NAME --output text | grep $CARTS_TEAM_IAM_ROLE || true)

if [ ! -z "$carts_check" ]; then
  aws eks delete-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $CARTS_TEAM_IAM_ROLE
fi

admins_check=$(aws eks list-access-entries --cluster-name $EKS_CLUSTER_NAME --output text | grep $ADMINS_IAM_ROLE || true)

if [ ! -z "$admins_check" ]; then
  aws eks delete-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $ADMINS_IAM_ROLE
fi