#!/bin/bash

set -e

source ./hack/lib/kubectl-version.sh

# Check if kubectl already exists in ~/bin
if [ ! -f ~/bin/kubectl ]; then
  echo "Downloading kubectl..."
  
  # Detect OS and architecture
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  # Map architecture names
  if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="arm64"
  fi

  wget -q https://dl.k8s.io/release/$KUBECTL_VERSION/bin/$OS/$ARCH/kubectl
  chmod +x ./kubectl

  mkdir -p ~/bin
  mv ./kubectl ~/bin
else
  echo "kubectl already exists in ~/bin, skipping download"
fi

export PATH="$PATH:$HOME/bin"

export MANIFESTS_REF="$BRANCH"

if [[ $BRANCH = build-* ]]; then
  export LAB_TIMES_ENABLED='true'
fi

yarn install --immutable
yarn workspace website clear
yarn workspace website build
