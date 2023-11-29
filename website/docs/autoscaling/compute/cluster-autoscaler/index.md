---
title: "Cluster Autoscaler (CA)"
sidebar_position: 20
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/compute/cluster-autoscaler
```

This will make the following changes to your lab environment:
- Install the Kubernetes Cluster Autoscaler in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform).

:::

In this lab, we'll look at the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler), a component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run without unneeded nodes. The Cluster Autoscaler is a great tool to ensure that the underlying cluster infrastructure is elastic, scalable, and can meet the changing demands of workloads.

The Kubernetes Cluster Autoscaler automatically adjusts the size of a Kubernetes cluster when one of the following conditions is true:

1. There are pods that fail to run in a cluster due to insufficient resources.
2. There are nodes in a cluster that are underutilized for an extended period of time and their pods can be placed on other existing nodes.

Cluster Autoscaler for AWS provides [integration with Auto Scaling groups](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws). 

In this lab exercise, we'll apply the Cluster Autoscaler to our EKS cluster and see how it behaves when we scale up our workloads.
