#!/bin/bash

set -e

logmessage "Cleaning up Kyverno resources..."

delete-all-if-crd-exists admissionreports.kyverno.io
delete-all-if-crd-exists backgroundscanreports.kyverno.io
delete-all-if-crd-exists cleanuppolicies.kyverno.io
delete-all-if-crd-exists clusteradmissionreports.kyverno.io
delete-all-if-crd-exists clusterbackgroundscanreports.kyverno.io
delete-all-if-crd-exists clustercleanuppolicies.kyverno.io
delete-all-if-crd-exists clusterpolicies.kyverno.io
delete-all-if-crd-exists policies.kyverno.io
delete-all-if-crd-exists policyexceptions.kyverno.io
delete-all-if-crd-exists updaterequests.kyverno.io

kubectl -n default delete pods --all
