#!/bin/bash

set -e

logmessage "Deleting Gradio-UI components..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio-mistral --ignore-not-found

logmessage "Deleting mistral pods..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/ray-service-neuron-mistral-chatbot --ignore-not-found

logmessage "Deleting mistral and gradio-mistral-trn1 namespaces..."

kubectl delete namespace mistral --ignore-not-found

kubectl delete namespace gradio-mistral-trn1 --ignore-not-found

logmessage "Deleting Neuron device plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Uninstalling kuberay operator..."

uninstall-helm-chart kuberay-operator default

logmessage "Deleting Karpenter resources..."

kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl delete --ignore-not-found -f-