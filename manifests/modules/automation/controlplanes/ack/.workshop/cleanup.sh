#!/bin/bash

logmessage "Deleting resources created by ACK..."

eksctl delete iamserviceaccount --name carts-ack --namespace carts --cluster $EKS_CLUSTER_NAME -v 0
kubectl delete table items -n carts --ignore-not-found=true