---
title: Using eksctl
sidebar_position: 20
---

This section outlines how to build a cluster for the lab exercises using the [eksctl tool](https://eksctl.io/). This is the easiest way to get started, and is recommended for most learners.

First, access the Cloud9 IDE created in the previous section by using [these instructions](../../ide.md).

The `eksctl` utility has been pre-installed in Cloud9 so we can immediately create the cluster.

This is the configuration that will be used to build the cluster:

```file
../cluster/eksctl/cluster.yaml
```

It will:
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Use this configuration file like so:

```bash test=false
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

