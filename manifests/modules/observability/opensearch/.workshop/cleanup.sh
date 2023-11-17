#!/bin/bash

set -e

echo "Deleting OpenSearch exporter and test workloads..."

uninstall-helm-chart events-to-opensearch opensearch-exporter
uninstall-helm-chart fluentbit opensearch-exporter

kubectl delete ns opensearch-exporter --ignore-not-found > /dev/null
kubectl delete ns test --ignore-not-found > /dev/null

# Delete the CloudWatch logs subscription filter
echo "Delete CloudWatch subscription filter for EKS control plane logs..."
aws logs delete-subscription-filter \
    --log-group-name /aws/eks/$EKS_CLUSTER_NAME/cluster \
    --filter-name "${EKS_CLUSTER_NAME}-Control-Plane-Logs-To-OpenSearch"

# Disable EKS cluster logging and wait for cluster to become active 
echo "Disabling EKS control plane logs..."
aws eks update-cluster-config \
    --region $AWS_REGION \
    --name $EKS_CLUSTER_NAME \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' 

aws eks wait cluster-active --name $EKS_CLUSTER_NAME 
