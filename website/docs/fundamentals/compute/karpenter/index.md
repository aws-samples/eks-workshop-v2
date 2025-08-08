---
title: "Karpenter"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Automatically manage compute for Amazon Elastic Kubernetes Service with Karpenter."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=30
$ prepare-environment autoscaling/compute/karpenter
```

This will make the following changes to your lab environment:

- Installs various IAM roles and other AWS resources required by Karpenter

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/karpenter/.workshop/terraform).

:::

In this lab, we'll look at [Karpenter](https://github.com/aws/karpenter), an open-source autoscaling project built for Kubernetes. Karpenter is designed to provide the right compute resources to match your application’s needs in seconds, not minutes, by observing the aggregate resource requests of unschedulable pods and making decisions to launch and terminate nodes to minimize scheduling latencies.

<img src={require('./assets/karpenter-diagram.webp').default}/>

Karpenter's goal is to improve the efficiency and cost of running workloads on Kubernetes clusters. Karpenter works by:

- Watching for pods that the Kubernetes scheduler has marked as unschedulable
- Evaluating scheduling constraints (resource requests, node selectors, affinities, tolerations, and topology spread constraints) requested by the pods
- Provisioning nodes that meet the requirements of the pods
- Scheduling the pods to run on the new nodes
- Removing the nodes when the nodes are no longer needed
