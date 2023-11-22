#!/bin/bash

set -e

echo "Deleting EFS storage class..."

kubectl delete storageclass efs-sc --ignore-not-found > /dev/null
