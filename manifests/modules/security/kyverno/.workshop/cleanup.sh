#!/bin/bash

set -e

logmessage "Cleaning up Kyverno resources..."

delete-all-if-crd-exists admissionreports.kyverno.io
delete-all-if-crd-exists backgroundscanreports.kyverno.io
delete-all-if-crd-exists cleanuppolicies.kyverno.io
delete-all-if-crd-exists clusteradmissionreports.kyverno.io
delete-all-if-crd-exists clusterbackgroundscanreports.kyverno.io
delete-all-if-crd-exists clustercleanuppolicies.kyverno.io
delete-all-if-crd-exists clusterpolicies.kyverno.io
delete-all-if-crd-exists policies.kyverno.io
delete-all-if-crd-exists policyexceptions.kyverno.io
delete-all-if-crd-exists updaterequests.kyverno.io

# Delete Kyverno admission webhooks to prevent Helm uninstall from hanging.
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=kyverno --ignore-not-found=true
kubectl delete mutatingwebhookconfigurations -l app.kubernetes.io/instance=kyverno --ignore-not-found=true

# Uninstall Kyverno Helm releases directly here with --no-hooks and --wait=false
# so Terraform destroy has nothing to do and completes instantly.
# --no-hooks skips the webhooksCleanup job which can hang during teardown.
if helm status kyverno -n kyverno &>/dev/null; then
  helm uninstall kyverno-policies -n kyverno --no-hooks --wait=false --ignore-not-found 2>/dev/null || true
  helm uninstall kyverno -n kyverno --no-hooks --wait=false --ignore-not-found 2>/dev/null || true
fi

kubectl -n default delete pods --all
