#!/bin/bash

set -e

logmessage "Deleting vLLM namespace..."

kubectl delete namespace vllm --ignore-not-found

logmessage "Deleting Neuron device plugin..."

uninstall-helm-chart neuron-helm-chart kube-system

logmessage "Deleting Karpenter resources..."

kubectl delete nodepool --all
kubectl delete ec2nodeclass --all