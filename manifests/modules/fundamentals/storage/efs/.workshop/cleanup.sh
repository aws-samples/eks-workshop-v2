#!/bin/bash

echo "Deleting EFS storage class..."

kubectl delete storageclass efs-sc > /dev/null
