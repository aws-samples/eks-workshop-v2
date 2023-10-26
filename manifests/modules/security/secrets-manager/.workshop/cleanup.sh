#!/bin/bash

set -e

kubectl delete clustersecretstore cluster-secret-store --ignore-not-found > /dev/null

kubectl delete SecretProviderClass catalog-spc -n catalog --ignore-not-found > /dev/null

kubectl delete ExternalSecret catalog-external-secret -n catalog --ignore-not-found > /dev/null

check=$(aws secretsmanager list-secrets --filters Key="name",Values="${SECRET_NAME}" --output text)

if [ ! -z "$check" ]; then
  echo "Deleting Secrets Manager data..."
  aws secretsmanager delete-secret --secret-id ${SECRET_NAME}
fi