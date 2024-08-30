#!/bin/bash

set -e

logmessage "Deleting AIML resources..."

logmessage "Deleting Gradio-UI Components..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/gradio --ignore-not-found=true

logmessage "Deleting Llama2 pods..."

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin-rbac.yml
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin.yml

logmessage "Deleting Neuron Device Plugin..."

kubectl delete -k /eks-workshop/manifests/modules/aiml/chatbot/neuron-device-plugin --ignore-not-found=true

logmessage "Un-installing kuberay operator..."

helm uninstall kuberay-operator

kubectl delete namespace llama2 --ignore-not-found

kubectl delete namespace gradio-llama2-inf2 --ignore-not-found

logmessage "Deleting Karpenter NodePool and EC2NodeClass..."

delete-all-if-crd-exists nodepools.karpenter.sh
delete-all-if-crd-exists ec2nodeclasses.karpenter.k8s.aws

logmessage "Waiting for Karpenter nodes to be removed..."

EXIT_CODE=0

timeout --foreground -s TERM 30 bash -c \
    'while [[ $(kubectl get nodes --selector=type=karpenter -o json | jq -r ".items | length") -gt 0 ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  logmessage "Warning: Karpenter nodes did not clean up"
fi
