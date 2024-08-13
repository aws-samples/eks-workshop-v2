
---
title: "Cluster Autoscaler (CA)"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Automatically manage compute for Amazon Elastic Kubernetes Service with Cluster Autoscaler."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/compute/cluster-autoscaler
```

This will make the following changes to your lab environment:

- Create an IAM role that will be used by cluster-autoscaler

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform).

:::

In this lab, we'll explore the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler), a component that automatically adjusts the size of a Kubernetes Cluster to ensure all pods have a place to run without unnecessary nodes. The Cluster Autoscaler is an excellent tool for maintaining elastic, scalable cluster infrastructure that can meet changing workload demands.

The Kubernetes Cluster Autoscaler automatically adjusts the size of a Kubernetes cluster when one of the following conditions is true:

1. There are pods that fail to run in the cluster due to insufficient resources.
2. There are nodes in the cluster that have been underutilized for an extended period, and their pods can be placed on other existing nodes.

Cluster Autoscaler for AWS provides [integration with Auto Scaling groups](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws).

In this lab exercise, we'll apply the Cluster Autoscaler to our EKS cluster and observe its behavior when we scale up our workloads.
