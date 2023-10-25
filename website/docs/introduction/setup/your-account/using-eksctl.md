---
title: Using eksctl
sidebar_position: 20
---

This section outlines how to build a cluster for the lab exercises using the [eksctl tool](https://eksctl.io/). This is the easiest way to get started, and is recommended for most learners.

The `eksctl` utility has been pre-installed in Cloud9 so we can immediately create the cluster.

:::tip

You can choose to do the labs using either IPv4 or IPv6 VPC networking. Unless otherwise needed it is recommended to use IPv4 since there are some labs that do not function with IPv6. Select the appropriate tab below.

Once you have built a cluster with a particular network family you will need to recreate the cluster if you wish to switch.

:::

<tabs groupId="ip-version">
  <tabItem value="ipv4" label="IPv4">

This is the configuration that will be used to build a cluster that uses IPv4 networking:

```file hidePath=true
manifests/../cluster/eksctl/ipv4/cluster.yaml
```

```bash test=false
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/ipv4/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

  </tabItem>
  <tabItem value="ipv6" label="IPv6">

This is the configuration that will be used to build a cluster that uses IPv6 networking:

```file hidePath=true
manifests/../cluster/eksctl/ipv6/cluster.yaml
```

```bash test=false
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/ipv6/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

  </tabItem>
</tabs>

Based on this configuration `eksctl` will:
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation (only in IPv4 mode)

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
