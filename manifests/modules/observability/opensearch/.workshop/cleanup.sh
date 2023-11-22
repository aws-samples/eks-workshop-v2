#!/bin/bash

echo "Deleting OpenSearch exporter and test workloads..."

uninstall-helm-chart events-to-opensearch opensearch-exporter
uninstall-helm-chart fluentbit opensearch-exporter

kubectl delete ns opensearch-exporter --ignore-not-found > /dev/null
kubectl delete ns test --ignore-not-found > /dev/null