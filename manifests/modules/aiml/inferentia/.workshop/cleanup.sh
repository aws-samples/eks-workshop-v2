#!/bin/bash

set -e

logmessage "Deleting inferentia namespaces..."

kubectl delete namespace aiml --ignore-not-found

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Deleting Karpenter resources..."

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws