#!/bin/bash

echo "Deleting OpenTelemetry collectors..."

kubectl delete opentelemetrycollector --all -A > /dev/null

kubectl delete -n other pod load-generator --ignore-not-found > /dev/null