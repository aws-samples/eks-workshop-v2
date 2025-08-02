---
title: Using eksctl
sidebar_position: 20
---

This section outlines how to build a cluster for the lab exercises using the [eksctl tool](https://eksctl.io/). This is the easiest way to get started, and is recommended for most learners.

The `eksctl` utility has been pre-installed in your IDE environment, so we can immediately create the cluster. This is the configuration that will be used to build the cluster:

::yaml{file="manifests/../cluster/eksctl/cluster.yaml" paths="availabilityZones,metadata.name,iam,managedNodeGroups,addons.0.configurationValues" title="cluster.yaml"}

1. Create a VPC across three availability zones
2. Create an EKS cluster, which default is named `eks-workshop`
3. Create an IAM OIDC provider
4. Add a managed node group named `default`
5. Configure the VPC CNI to use prefix delegation

Apply the configuration file like so:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

This process will take approximately 20 minutes to complete.

## Next Steps

Now that the cluster is ready, head to the [Navigating the labs](/docs/introduction/navigating-labs) section or skip ahead to any module in the workshop using the top navigation bar. Once you've completed the workshop, follow the steps below to clean up your environment.

## Cleaning Up (steps once you are done with the Workshop)

:::tip
The following demonstrates how to clean up resources once you are done using the EKS cluster. Completing these steps will prevent further charges to your AWS account.
:::

Before deleting the IDE environment, clean up the cluster that we set up in previous steps.

First, use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next, delete the cluster with `eksctl`:

```bash
$ eksctl delete cluster $EKS_CLUSTER_NAME --wait
```

You can now proceed to [cleaning](./cleanup.md) up the IDE.
