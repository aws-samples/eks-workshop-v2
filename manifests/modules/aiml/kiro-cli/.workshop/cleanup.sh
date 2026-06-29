#!/bin/bash

set -e

logmessage "Deleting failing pod..."

kubectl delete -f /eks-workshop/manifests/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml --ignore-not-found

logmessage "Deleting Kiro IDC stack..."

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' | rev | cut -d'/' -f1 | rev)
aws cloudformation delete-stack --stack-name "${CLUSTER_NAME}-kiro-idc" || true
aws cloudformation wait stack-delete-complete --stack-name "${CLUSTER_NAME}-kiro-idc" || true
