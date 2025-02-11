#!/bin/bash

set -e

logmessage "Deleting Gradio-UI Components..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio --ignore-not-found

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio-mistral --ignore-not-found

logmessage "Deleting Llama2 and mistral pods..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/ray-service-llama2-chatbot --ignore-not-found

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/ray-service-neuron-mistral-chatbot --ignore-not-found

logmessage "Deleting persistent volume claim and storage class"

kubectl delete pvc model-cache-pvc -n mistral --ignore-not-found

kubectl delete storageclass ebs-gp3 -n mistral --ignore-not-found

logmessage "Deleting mistral, gradio-mistral-inf2, llama2, and gradio-llama2-inf2 namespaces..."

kubectl delete namespace llama2 --ignore-not-found

kubectl delete namespace gradio-llama2-inf2 --ignore-not-found

kubectl delete namespace mistral --ignore-not-found

kubectl delete namespace gradio-mistral-inf2 --ignore-not-found

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found


logmessage "Un-installing kuberay operator..."

helm uninstall kuberay-operator --ignore-not-found

logmessage "Deleting Karpenter resources..."

kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl delete --ignore-not-found -f-