#!/bin/bash

set -e

logmessage "Deleting ArgoCD applications..."

delete-all-and-wait-if-crd-exists applications.argoproj.io

rm -rf ~/environment/argocd