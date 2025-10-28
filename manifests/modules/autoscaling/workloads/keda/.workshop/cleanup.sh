#!/bin/bash

set -e

kubectl delete pod load-generator --ignore-not-found
delete-all-if-crd-exists scaledobjects.keda.sh
kubectl delete ingress ui -n ui --ignore-not-found

uninstall-helm-chart keda keda
kubectl delete ns keda --ignore-not-found
