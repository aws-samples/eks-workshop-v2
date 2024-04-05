#!/bin/bash

logmessage "Deleting resources created by ACK..."

eksctl delete iamserviceaccount --name carts-ack --namespace carts --cluster $EKS_CLUSTER_NAME -v 0
delete-all-if-crd-exists tables.dynamodb.services.k8s.aws