#!/bin/bash

set -e

kubectl delete ingress -n catalog catalog --ignore-not-found
kubectl delete ingress -n ui ui --ignore-not-found

uninstall-helm-chart aws-load-balancer-controller kube-system