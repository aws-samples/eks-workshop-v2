#!/bin/bash

logmessage "Deleting OpenSearch exporters and test workloads..."

uninstall-helm-chart events-to-opensearch opensearch-exporter
uninstall-helm-chart fluentbit opensearch-exporter

logmessage "Deleting CloudWatch subscription filter for EKS control plane logs..."
aws logs delete-subscription-filter \
    --log-group-name /aws/eks/$EKS_CLUSTER_NAME/cluster \
    --filter-name "${EKS_CLUSTER_NAME}-Control-Plane-Logs-To-OpenSearch"

logmessage "Disabling EKS control plane logs..."
aws eks update-cluster-config \
    --region $AWS_REGION \
    --name $EKS_CLUSTER_NAME \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' 

aws eks wait cluster-active --name $EKS_CLUSTER_NAME 

kubectl delete ns opensearch-exporter --ignore-not-found
kubectl delete ns test --ignore-not-found
