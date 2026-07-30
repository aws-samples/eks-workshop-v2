#!/bin/bash

set -e

logmessage "Deleting failing pod..."

kubectl delete -f /eks-workshop/manifests/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml --ignore-not-found
