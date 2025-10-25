#!/bin/bash

set -e

source ./hack/lib/kubectl-version.sh

wget -q https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
chmod +x ./kubectl

mkdir ~/bin
mv ./kubectl ~/bin

export PATH="$PATH:$HOME/bin"

export MANIFESTS_REF="$BRANCH"

if [[ $BRANCH = build-* ]]; then
  export LAB_TIMES_ENABLED='true'
fi

yarn install --immutable
yarn workspace website clear
yarn workspace website build
