#!/bin/bash

echo "Deleting resources created by ACK..."

eksctl delete iamserviceaccount --name carts-ack --namespace carts --cluster $EKS_CLUSTER_NAME -v 0 > /dev/null
kubectl delete table items -n carts --ignore-not-found=true > /dev/null
kubectl delete namespace ack-dynamodb --ignore-not-found=true > /dev/null

