#!/bin/bash

set -e

echo "Disabling EKS control plane logs..."

aws eks update-cluster-config \
    --region $AWS_REGION \
    --name $EKS_CLUSTER_NAME \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' || true > /dev/null

aws eks wait cluster-active --name $EKS_CLUSTER_NAME > /dev/null