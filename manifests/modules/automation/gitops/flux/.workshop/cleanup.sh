#!/bin/bash

set -e

logmessage "Uninstalling flux"

flux uninstall --silent

kubectl delete namespace ui --ignore-not-found=true

rm -rf ~/environment/flux

logmessage "Uninstalling Gitea"

uninstall-helm-chart gitea gitea

kubectl delete namespace gitea --ignore-not-found=true