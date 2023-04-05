#!/bin/bash

echo "Deleting RDS resources created by Crossplane..."

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/compositions/claim --ignore-not-found=true > /dev/null
kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/compositions/composition --ignore-not-found=true > /dev/null

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/managed/ --ignore-not-found=true > /dev/null