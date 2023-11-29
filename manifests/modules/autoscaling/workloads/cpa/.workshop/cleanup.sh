#!/bin/bash

set -e

echo "Resetting CoreDNS replicas..."

kubectl -n kube-system scale deployment/coredns --replicas=2 > /dev/null