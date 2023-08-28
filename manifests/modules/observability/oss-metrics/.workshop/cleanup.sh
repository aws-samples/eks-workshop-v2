#!/bin/bash

echo "Deleting OpenTelemetry collectors..."

delete-all-if-crd-exists opentelemetrycollectors.opentelemetry.io