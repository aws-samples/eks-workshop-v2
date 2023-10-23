#!/bin/bash

echo "Deleting OpenSearch exporter and test workloads..."
helm uninstall events-to-opensearch -n opensearch-exporter > /dev/null 2>&1
kubectl delete events-to-opensearch > /dev/null 2>&1
kubectl delete ns test > /dev/null 2>&1
