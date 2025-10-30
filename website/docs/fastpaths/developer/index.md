---
title: "Developer Essentials"
sidebar_position: 40
sidebar_custom_props: { "module": true }
---

# Developer Essentials

::required-time

:::tip Before you start
This fast path uses a dedicated Amazon EKS Auto Mode cluster. Amazon EKS Auto Mode extends AWS management of Kubernetes clusters beyond the cluster itself, managing infrastructure that enables smooth operation of your workloads including compute autoscaling, networking, load balancing, DNS, and block storage.

Switch to the Auto Mode cluster:

```bash
$ prepare-environment fastpaths/developer
```
:::

Welcome to the EKS Workshop Developer Essentials! This is a collection of labs optimized for developers to learn the features of Amazon EKS most commonly required when deploying workloads.

Throughout this series of exercises you'll learn:

- How to deploy and manage containerized applications on EKS
- Working with persistent storage using Amazon EBS
- Implementing autoscaling for your workloads
- Exposing applications with load balancers and DNS
- Using AWS services like DynamoDB with EKS Pod Identity

Let's get started!
