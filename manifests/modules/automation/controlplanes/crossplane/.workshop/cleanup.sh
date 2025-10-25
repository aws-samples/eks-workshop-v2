#!/bin/bash

logmessage "Deleting resources created by Crossplane..."

delete-all-and-wait-if-crd-exists dynamodbtables.awsblueprints.io

kubectl delete tables.dynamodb.aws.upbound.io --all --ignore-not-found=true

kubectl wait --for=delete tables.dynamodb.aws.upbound.io --all --timeout=600s

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/compositions/composition --ignore-not-found=true

kubectl wait --for=delete composition table.dynamodb.awsblueprints.io --timeout=600s

eksctl delete iamserviceaccount --name carts-crossplane --namespace carts --cluster $EKS_CLUSTER_NAME -v 0