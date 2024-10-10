#!/bin/bash

set -e

logmessage "Deleting OpenTelemetry collectors..."

kubectl delete -n other instrumentation retail-store --ignore-not-found
kubectl delete -n other opentelemetrycollector adot --ignore-not-found
kubectl delete clusterrolebinding otel-prometheus-role-binding --ignore-not-found
kubectl delete clusterrole otel-prometheus-role --ignore-not-found
kubectl delete -n other serviceaccount adot-collector --ignore-not-found

delete-all-if-crd-exists certificaterequests.cert-manager.io
delete-all-if-crd-exists certificates.cert-manager.io
delete-all-if-crd-exists challenges.acme.cert-manager.io
delete-all-if-crd-exists clusterissuers.cert-manager.io
delete-all-if-crd-exists issuers.cert-manager.io
delete-all-if-crd-exists orders.acme.cert-manager.io
delete-all-if-crd-exists grafanaalertrulegroups.grafana.integreatly.org
delete-all-if-crd-exists grafanacontactpoints.grafana.integreatly.org
delete-all-if-crd-exists grafanadashboards.grafana.integreatly.org
delete-all-if-crd-exists grafanadatasources.grafana.integreatly.org
delete-all-if-crd-exists grafanafolders.grafana.integreatly.org
delete-all-if-crd-exists grafananotificationpolicies.grafana.integreatly.org
delete-all-if-crd-exists grafanas.grafana.integreatly.org
delete-all-if-crd-exists grafanaagents.monitoring.grafana.com
delete-all-if-crd-exists integrations.monitoring.grafana.com
delete-all-if-crd-exists logsinstances.monitoring.grafana.com
delete-all-if-crd-exists metricsinstances.monitoring.grafana.com
delete-all-if-crd-exists podlogs.monitoring.grafana.com
delete-all-if-crd-exists podmonitors.monitoring.coreos.com
delete-all-if-crd-exists probes.monitoring.coreos.com
delete-all-if-crd-exists servicemonitors.monitoring.coreos.com

kubectl delete -n other pod load-generator --ignore-not-found