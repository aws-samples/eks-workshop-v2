---
title: Using eksctl
sidebar_position: 20
---

This section outlines how to build a cluster for the lab exercises using the [eksctl tool](https://eksctl.io/). This is the easiest way to get started, and is recommended for most learners.

The `eksctl` utility has been pre-installed in your Amazon Cloud9 Environment, so we can immediately create the cluster. This is the configuration that will be used to build the cluster:

```file hidePath=true
manifests/../cluster/eksctl/cluster.yaml
```

Based on this configuration `eksctl` will:
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Apply the configuration file like so:

```bash test=false
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

This generally takes 20 minutes. Once the cluster is created run this command to use the cluster for the lab exercises:

```bash test=false
$ use-cluster $EKS_CLUSTER_NAME
```

Now that the cluster is ready, head to the [Getting Started](/docs/introduction/getting-started) module or skip ahead to any module in the workshop with the top navigation bar. Once you're completed with the workshop, follow the steps below to clean-up your environment.

## Cleaning Up

Before deleting the Cloud9 environment we need to clean up the cluster that we set up above.

First use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash test=false
$ delete-environment
```

Next delete the cluster with `eksctl`:

```bash test=false
$ eksctl delete cluster $EKS_CLUSTER_NAME --wait
```