#!/bin/bash

set -e

logmessage "NOTE: Cleaning up this lab may take several minutes, as we need to recycle the EC2 instances..."

uninstall-helm-chart cluster-autoscaler kube-system