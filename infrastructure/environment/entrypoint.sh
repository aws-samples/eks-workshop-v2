#!/bin/bash

set -e

if [ ! -z "$EKS_CLUSTER_NAME" ]; then
  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
fi

# TODO: Move to .bashrc or similar
export AWS_PAGER=""

sed -i 's/^plugins=.*/plugins=(git kubectl aws)/g' ~/.zshrc

echo 'PROMPT="%(?:%{$fg_bold[green]%}eks-workshop ➜ :%{$fg_bold[red]%}➜ )%{$reset_color%}"' >> ~/.zshrc

zsh -l