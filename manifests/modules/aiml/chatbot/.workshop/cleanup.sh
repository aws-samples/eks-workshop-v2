#!/bin/bash

set -e

logmessage "Deleting AIML resources..."

logmessage "Deleting Gradio-UI Components..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio --ignore-not-found

logmessage "Deleting Llama2 pods..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/ray-service-llama2-chatbot --ignore-not-found

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin-rbac.yml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin.yml --ignore-not-found

logmessage "Un-installing kuberay operator..."

helm uninstall kuberay-operator --ignore-not-found

kubectl delete namespace llama2 --ignore-not-found

kubectl delete namespace gradio-llama2-inf2 --ignore-not-found
