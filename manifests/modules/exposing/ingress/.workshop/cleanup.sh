#!/bin/bash

set -e

kubectl delete ingress -n catalog --all --ignore-not-found
kubectl delete ingress -n ui --all --ignore-not-found

uninstall-helm-chart external-dns external-dns

uninstall-helm-chart aws-load-balancer-controller kube-system