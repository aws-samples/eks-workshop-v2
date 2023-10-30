#!/bin/bash

echo "Deleting resources created by Crossplane... (this will take several minutes)"

delete-all-if-crd-exists dynamodbtables.awsblueprints.io

delete-all-if-crd-exists xdynamodbtables.awsblueprints.io

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/managed/ --ignore-not-found=true > /dev/null

kubectl delete -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/compositions/composition --ignore-not-found=true > /dev/null

exit 0