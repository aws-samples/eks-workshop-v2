#!/bin/bash

echo "Deleting OpenSearch exporter and test workloads..."
helm uninstall events-to-opensearch -n opensearch-exporter > /dev/null 2>&1
kubectl delete ns o11y-test > /dev/null 2>&1
