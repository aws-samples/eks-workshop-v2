#!/bin/bash

set -e

echo "Deleting OpenSearch exporter and test workloads..."

# Redirect errors to /dev/null since the participant may have skipped over instruction during the lab
helm uninstall events-to-opensearch -n opensearch-exporter > /dev/null 2>&1
helm uninstall fluentbit -n opensearch-exporter > /dev/null 2>&1
kubectl delete ns opensearch-exporter > /dev/null 2>&1
kubectl delete ns test > /dev/null 2>&1

# Delete the CloudWatch logs subscription filter
 aws logs delete-subscription-filter \
    --log-group-name /aws/eks/$EKS_CLUSTER_NAME/cluster \
    --filter-name "${EKS_CLUSTER_NAME}-Control-Plane-Logs-To-OpenSearch" > /dev/null

# Disable EKS cluster logging and wait for cluster to become active 
echo "Disabling EKS control plane logs..."
aws eks update-cluster-config \
    --region $AWS_REGION \
    --name $EKS_CLUSTER_NAME \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' > /dev/null

aws eks wait cluster-active --name $EKS_CLUSTER_NAME > /dev/null

# Confirm that the fluentbit helm chart has been deleted 
helm status fluentbit -n opensearch-exporter > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "WARNING: fluentbit cleanup failed. Run the following command to manually uninstall fluentbit:"
  echo "  helm uninstall fluentbit -n opensearch-exporter"
fi

# Confirm that the events exporter helm chart has been deleted
helm status events-to-opensearch -n opensearch-exporter > /dev/null 2>&1
if [  $? -eq 0  ]; then
  echo "WARNING: Kubernetes events exporter cleanup failed. Run the following command to manually uninstall Kubernetes events exporter:"
  echo "  helm uninstall events-to-opensearch -n opensearch-exporter"
fi
