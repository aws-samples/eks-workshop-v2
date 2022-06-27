#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t eks-workshop-helm-updater $SCRIPT_DIR/../helm

docker run -it -v $SCRIPT_DIR/../terraform/modules/cluster:/terraform eks-workshop-helm-updater