#!/bin/bash

set -e

logmessage "Deleting Karpenter NodePool and EC2NodeClass..."

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws

logmessage "Waiting for Karpenter nodes to be removed..."

EXIT_CODE=0

timeout --foreground -s TERM 30 bash -c \
    'while [[ $(kubectl get nodes --selector=type=karpenter -o json | jq -r ".items | length") -gt 0 ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  logmessage "Warning: Karpenter nodes did not clean up"
fi

uninstall-helm-chart karpenter karpenter