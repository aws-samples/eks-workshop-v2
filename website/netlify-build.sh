#!/bin/bash

set -e

wget -q https://dl.k8s.io/release/v1.23.9/bin/linux/amd64/kubectl
chmod +x ./kubectl

mkdir ~/bin
mv ./kubectl ~/bin

export PATH="$PATH:$HOME/bin"

npm install
npm run build
