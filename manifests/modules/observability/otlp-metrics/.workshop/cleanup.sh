#!/bin/bash

set -e

logmessage "Cleaning up OTLP metrics resources..."

kubectl delete amazoncloudwatchagent application-metrics-collector -n amazon-cloudwatch --ignore-not-found
kubectl delete -n other pod load-generator --ignore-not-found

logmessage "Disabling OTel enrichment..."
aws cloudwatch stop-otel-enrichment 2>/dev/null || true

logmessage "Disabling resource tags on telemetry..."
aws observabilityadmin stop-telemetry-enrichment 2>/dev/null || true
