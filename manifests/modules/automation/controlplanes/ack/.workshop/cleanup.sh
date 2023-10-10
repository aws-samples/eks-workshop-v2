#!/bin/bash

echo "Deleting resources created by ACK..."

kubectl delete table items -n carts > /dev/null
