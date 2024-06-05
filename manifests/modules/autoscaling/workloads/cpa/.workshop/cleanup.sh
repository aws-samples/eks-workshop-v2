#!/bin/bash

set -e

uninstall-helm-chart cluster-proportional-autoscaler kube-system

logmessage "Resetting CoreDNS replicas..."

kubectl -n kube-system scale deployment/coredns --replicas=2