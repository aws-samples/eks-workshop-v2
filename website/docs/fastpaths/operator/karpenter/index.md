---
title: "Autoscaling with EKS Auto Mode"
sidebar_position: 20
description: "Automatically manage compute for Amazon Elastic Kubernetes Service with EKS Auto Mode."
---

::required-time

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes fully-managed autoscaling powered by **Karpenter**, which enables automatic compute scaling out of the box.
:::

In this lab, we'll explore how EKS Auto Mode provides automatic compute scaling for your cluster. Auto Mode includes fully-managed [Karpenter](https://github.com/aws/karpenter) functionality as part of a comprehensive suite of managed features that minimize operational burden. The autoscaling capability is designed to provide the right compute resources to match your application's needs in seconds, not minutes, by observing the aggregate resource requests of unschedulable pods and making decisions to launch and terminate nodes to minimize scheduling latencies.

<img src={require('./assets/karpenter-diagram.webp').default}/>

EKS Auto Mode's autoscaling works by:

- Watching for pods that the Kubernetes scheduler has marked as unschedulable
- Evaluating scheduling constraints (resource requests, node selectors, affinities, tolerations, and topology spread constraints) requested by the pods
- Provisioning nodes that meet the requirements of the pods
- Scheduling the pods to run on the new nodes
- Removing the nodes when the nodes are no longer needed

:::info
With EKS Auto Mode, Karpenter is fully managed by AWS and runs off-cluster. Unlike self-managed Karpenter, you don't need to deploy, scale, or upgrade Karpenter pods. All operational aspects are handled by AWS, while you retain control over NodePool and NodeClass configurations.
:::

Since Auto Mode provides fully-managed autoscaling, we can move directly to configuring NodePools to control how nodes are provisioned for your workloads.
