#!/bin/bash

set -e

rm -rf ~/environment/codepipeline

uninstall-helm-chart ui ui

kubectl delete namespace ui --ignore-not-found

aws eks delete-access-entry --cluster-name ${EKS_CLUSTER_NAME} \
  --principal-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-codepipeline-role" || true