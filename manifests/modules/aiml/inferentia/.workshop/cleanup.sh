#!/bin/bash

set -e

logmessage "Delete Inferentia Pods..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/inferentia/compiler --ignore-not-found

kubectl delete -k /eks-workshop/manifests/modules/aiml/inferentia/inference --ignore-not-found

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Deleting Karpenter resources..."

kubectl delete -k ~/environment/eks-workshop/modules/aiml/inferentia/nodepool --ignore-not-found

logmessage "Deleting inferentia namespaces..."

kubectl delete namespace aiml --ignore-not-found