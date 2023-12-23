#!/bin/bash

set -e

logmessage "Deleting OpenTelemetry collectors..."

delete-all-if-crd-exists opentelemetrycollectors.opentelemetry.io

kubectl delete -n other pod load-generator --ignore-not-found