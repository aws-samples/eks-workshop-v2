#!/bin/bash

echo "Deleting resources created by ACK..."

kubectl delete table items -n carts --ignore-not-found=true > /dev/null
kubectl delete namespace ack-dynamodb --ignore-not-found=true > /dev/null
