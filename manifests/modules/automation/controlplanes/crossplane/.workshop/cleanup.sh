#!/bin/bash

echo "Deleting resources created by Crossplane... (this will take several minutes)"

delete-all-if-crd-exists relationaldatabases.awsblueprints.io

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/managed/ --ignore-not-found=true > /dev/null

kubectl wait --for=delete dbinstance.rds.aws.crossplane.io -l app.kubernetes.io/created-by=eks-workshop --timeout=600s > /dev/null
kubectl wait --for=delete securitygroup.ec2.aws.crossplane.io -l app.kubernetes.io/created-by=eks-workshop --timeout=300s > /dev/null
kubectl wait --for=delete dbsubnetgroup.database.aws.crossplane.io -l app.kubernetes.io/created-by=eks-workshop --timeout=300s > /dev/null

exit 0