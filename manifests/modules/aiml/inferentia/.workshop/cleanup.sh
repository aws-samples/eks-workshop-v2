#!/bin/bash

set -e

logmessage "Delete Inferentia Pods..."

kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/compiler \
  | envsubst | kubectl delete -f-


kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/inference \
  | envsubst | kubectl delete -f-


logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.20.0/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Deleting Karpenter resources..."

kubectl kustomize ~/environment/eks-workshop/moudles/aiml/inferentia/nodepool \
  | envsubst | kubectl delete -f-


kubectl delete namespace aiml --ignore-not-found