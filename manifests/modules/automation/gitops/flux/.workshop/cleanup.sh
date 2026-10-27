#!/bin/bash

set -e

logmessage "Uninstalling flux"

flux uninstall --silent

kubectl delete namespace ui --ignore-not-found=true

rm -rf ~/environment/flux

kubectl delete namespace -l app.kubernetes.io/created-by=eks-workshop