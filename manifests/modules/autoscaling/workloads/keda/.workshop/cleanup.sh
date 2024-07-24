#!/bin/bash

set -e

kubectl delete pod load-generator --ignore-not-found
kubectl delete scaledobject ui-hpa -n ui --ignore-not-found
kubectl delete ingress ui -n ui --ignore-not-found

uninstall-helm-chart keda keda
kubectl delete ns keda --ignore-not-found