---
title: "Cluster Autoscaler (CA)"
sidebar_position: 20
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

The [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler) is a component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run without unneeded nodes. The Cluster Autoscaler is a great tool to ensure that the underlying cluster infrastructure is elastic, scalable, and can meet the changing demands of workloads.

The Kubernetes Cluster Autoscaler automatically adjusts the size of a Kubernetes cluster when one of the following conditions is true:

1. There are pods that fail to run in the cluster due to insufficient resources.
2. There are nodes in the cluster that are underutilized for an extended period of time and their pods can be placed on other existing nodes.

Cluster Autoscaler for AWS provides [integration with Auto Scaling groups](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws). 

In this lab we will apply the Cluster Autoscaler to our EKS cluster and see how it behaves when we scale up our workloads.