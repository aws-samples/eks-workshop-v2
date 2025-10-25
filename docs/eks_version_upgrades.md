# EKS Workshop - EKS Version Upgrades

This document outlines the procedure to upgrade EKS versions for this workshop.

## Identify a kubectl version

The easiest way to do this seems to be to use the CHANGELOG file. For example for Kubernetes 1.25 you can find the latest version here:

https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.25.md

Alter that URL for the Kubernetes version you are updating to.

## Identify an AMI release

We never want to use the latest AMI due to the worker node upgrade scenario. This command will provide the name of the correct AMI for a specific version:

```
$ aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amazon-eks-node-1.25*" --query "Images[1].[Name,Description]" --output text
amazon-eks-node-1.25-v20230304  EKS Kubernetes Worker AMI with AmazonLinux2 image, (k8s: 1.25.6, containerd: 1.6.6-1.amzn2.0.2)
```

The name of the release expected by the EKS API for this AMI would be:

```
1.25.6-20230304
```

This is a combination of:

- the `k8s` value (`1.25.6`)
- the date string without the `v` (`20230304`)

## Update the version numbers

There are various places that reference the Kubernetes versions (Kubernetes, kubectl and AMI), make sure to update them all:

1. Docusaurus variables: `website/docusaurus.config.js`
1. IDE installer: `lab/scripts/installer.sh`
1. eksctl: `cluster/eksctl/cluster.yaml`
1. Terraform: `cluster/terraform/variables.tf`
1. Common kubectl: `hack/lib/kubectl-version.sh`
1. Renovatebot version constraints: `renovate.json`
