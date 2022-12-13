#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t eks-workshop-helm-updater $SCRIPT_DIR/../helm/src

docker run --rm -v $SCRIPT_DIR/../helm/charts.yaml:/config/charts.yaml \
  -v $SCRIPT_DIR/../terraform/modules/cluster:/terraform eks-workshop-helm-updater \
  -c /config/charts.yaml -o /terraform/helm_versions.tf.json
