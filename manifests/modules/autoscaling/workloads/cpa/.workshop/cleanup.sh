#!/bin/bash

set -e

logmessage "Resetting CoreDNS replicas..."

kubectl -n kube-system scale deployment/coredns --replicas=2