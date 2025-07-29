#!/bin/bash

set -e

kubectl delete namespace ui --ignore-not-found

kubectl delete storageclass fsxn-sc-nfs --ignore-not-found

logmessage "Deleting FSxN backend config..."
delete-all-if-crd-exists tridentbackendconfigs.trident.netapp.io

uninstall-helm-chart trident-operator trident