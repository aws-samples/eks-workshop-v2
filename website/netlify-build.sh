#!/bin/bash

set -e

wget -q https://dl.k8s.io/release/v1.27.7/bin/linux/amd64/kubectl
chmod +x ./kubectl

mkdir ~/bin
mv ./kubectl ~/bin

export PATH="$PATH:$HOME/bin"

export MANIFESTS_REF="$BRANCH"

if [[ $BRANCH = build-* ]]; then
  export LAB_TIMES_ENABLED='true'
fi

npm install
npm run build
