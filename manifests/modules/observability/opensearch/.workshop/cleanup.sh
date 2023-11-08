#!/bin/bash

echo "Deleting OpenSearch exporter and test workloads..."
helm uninstall events-to-opensearch -n opensearch-exporter > /dev/null 2>&1
helm uninstall fluentbit -n opensearch-exporter > /dev/null 2>&1
kubectl delete ns opensearch-exporter > /dev/null 2>&1
kubectl delete ns test > /dev/null 2>&1

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

