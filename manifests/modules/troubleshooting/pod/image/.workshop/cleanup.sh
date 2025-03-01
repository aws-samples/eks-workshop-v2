#!/bin/bash

if kubectl get deployment ui-new -n default > /dev/null 2>&1; then
    kubectl delete deploy ui-new -n default
else
    echo "delpoyment ui-new does not exist"
fi
