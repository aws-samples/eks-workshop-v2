---
title: "Autoscaling EKS infrastructure with Karpenter"
sidebar_position: 20
description: "Automatically manage compute for Amazon Elastic Kubernetes Service with Karpenter."
---

::required-time

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes the **Karpenter**, which enables EKS cluster autoscaling out of the box.
:::

In this lab, we'll look at [Karpenter](https://github.com/aws/karpenter), an open-source autoscaling project built for Kubernetes. Karpenter is designed to provide the right compute resources to match your application’s needs in seconds, not minutes, by observing the aggregate resource requests of unschedulable pods and making decisions to launch and terminate nodes to minimize scheduling latencies.

<img src={require('./assets/karpenter-diagram.webp').default}/>

Karpenter's goal is to improve the efficiency and cost of running workloads on Kubernetes clusters. Karpenter works by:

- Watching for pods that the Kubernetes scheduler has marked as unschedulable
- Evaluating scheduling constraints (resource requests, node selectors, affinities, tolerations, and topology spread constraints) requested by the pods
- Provisioning nodes that meet the requirements of the pods
- Scheduling the pods to run on the new nodes
- Removing the nodes when the nodes are no longer needed

As we don't need to install Karpenter, we can directly move on to configuring Karpenter so that it will provision infrastructure for our pods based on demand.
