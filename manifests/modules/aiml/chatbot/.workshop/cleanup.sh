#!/bin/bash

set -e

logmessage "Deleting Gradio-UI Components..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio --ignore-not-found

logmessage "Deleting Llama2 pods..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/ray-service-llama2-chatbot --ignore-not-found

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Un-installing kuberay operator..."

helm uninstall kuberay-operator --ignore-not-found

logmessage "Deleting Karpenter resources and CRDs..."

kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl delete -f-

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws
delete-all-if-crd-exists nodeclaims.karpenter.sh

logmessage "Deleting llama2 and gradio-llama2-inf2 namespaces..."

kubectl delete namespace llama2 --ignore-not-found

kubectl delete namespace gradio-llama2-inf2 --ignore-not-found
