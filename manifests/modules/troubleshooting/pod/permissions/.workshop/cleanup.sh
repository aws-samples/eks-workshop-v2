#!/bin/bash

aws eks update-kubeconfig --name eks-workshop

if kubectl get deployment ui-private -n default > /dev/null 2>&1; then
    kubectl delete deploy ui-private -n default
else
    echo "delpoyment ui-private does not exist"
fi

