#!/bin/bash

echo "Deleting RDS resources created by Crossplane..."

if kubectl get crds | grep -q "RelationalDatabase"; then
  kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/compositions/claim --ignore-not-found=true > /dev/null
fi

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/managed/ --ignore-not-found=true > /dev/null

kubectl wait --for=delete dbinstance.rds.aws.crossplane.io -l crossplane.io/claim-name=${EKS_CLUSTER_NAME}-catalog-composition --timeout=600s > /dev/null
kubectl wait --for=delete securitygroup.ec2.aws.crossplane.io -l crossplane.io/claim-name=${EKS_CLUSTER_NAME}-catalog-composition --timeout=300s > /dev/null
kubectl wait --for=delete dbsubnetgroup.database.aws.crossplane.io -l crossplane.io/claim-name=${EKS_CLUSTER_NAME}-catalog-composition --timeout=300s > /dev/null

exit 0