#!/bin/bash

set -e

logmessage "Deleting vLLM namespace..."

kubectl delete namespace vllm --ignore-not-found

logmessage "Deleting Neuron device plugin..."

uninstall-helm-chart neuron-helm-chart kube-system

logmessage "Deleting Karpenter resources..."

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws