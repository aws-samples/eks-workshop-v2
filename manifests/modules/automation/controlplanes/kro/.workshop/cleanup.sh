#!/bin/bash

set -e

logmessage "Deleting resources created by kro..."

delete-all-if-crd-exists webapplicationdynamodbs.kro.run

delete-all-if-crd-exists webapplications.kro.run

delete-all-if-crd-exists resourcegraphdefinitions.kro.run

kubectl delete crd/webapplicationdynamodbs.kro.run --ignore-not-found

kubectl delete crd/webapplications.kro.run --ignore-not-found

uninstall-helm-chart kro kro-system
