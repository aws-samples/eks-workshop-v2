---
title: "⚡ Fast path - Developers"
chapter: true
---

::required-time

:::tip Before you start
This fast path uses a dedicated Amazon EKS Auto Mode cluster. Amazon EKS Auto Mode extends AWS management of Kubernetes clusters beyond the cluster itself, managing infrastructure that enables smooth operation of your workloads including compute autoscaling, networking, load balancing, DNS, and block storage.

Switch to the Auto Mode cluster:

```bash
$ use-cluster eks-workshop-auto
```

:::

Welcome to the EKS Workshop fast path for developers! This is a collection of labs optimized for developers to learn the features of Amazon EKS most commonly required when deploying workloads.

Throughout this series of exercises you'll learn:

- How to deploy and manage containerized applications on EKS
- Working with persistent storage using Amazon EBS
- Implementing autoscaling for your workloads
- Exposing applications with load balancers and DNS
- Using AWS services like DynamoDB with EKS Pod Identity

Let's get started!
