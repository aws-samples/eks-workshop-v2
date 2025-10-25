#!/bin/bash

set -e

kubectl delete svc -n ui ui-nlb --ignore-not-found

uninstall-helm-chart aws-load-balancer-controller kube-system