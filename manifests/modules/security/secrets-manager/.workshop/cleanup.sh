#!/bin/bash

set -e

delete-all-if-crd-exists opentelemetrycollectors.opentelemetry.io

delete-all-if-crd-exists clustersecretstores.external-secrets.io

delete-all-if-crd-exists secretproviderclasses.secrets-store.csi.x-k8s.io

delete-all-if-crd-exists externalsecrets.external-secrets.io

check=$(aws secretsmanager list-secrets --filters Key="name",Values="${SECRET_NAME}" --output text)

if [ ! -z "$check" ]; then
  logmessage "Deleting Secrets Manager data..."
  aws secretsmanager delete-secret --secret-id ${SECRET_NAME}
fi