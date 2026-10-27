#!/bin/bash

set -e

kubectl delete ingress -n catalog --all --ignore-not-found
kubectl delete ingress -n ui --all --ignore-not-found

# Remove the readiness gate injection label added in the pod readiness gate lab
kubectl label namespace ui elbv2.k8s.aws/pod-readiness-gate-inject- 2> /dev/null || true

uninstall-helm-chart external-dns external-dns

uninstall-helm-chart aws-load-balancer-controller kube-system
