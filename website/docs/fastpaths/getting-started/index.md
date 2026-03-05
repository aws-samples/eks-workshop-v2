---
title: Getting started
sidebar_position: 30
description: "Deploy sample retail application in EKS."
sidebar_custom_props: { "module": true }
---

:::tip Before you start
This lab uses a dedicated Amazon EKS Auto Mode cluster. Amazon EKS Auto Mode extends AWS management of Kubernetes clusters beyond the cluster itself, managing infrastructure that enables smooth operation of your workloads including compute autoscaling, networking, load balancing, DNS, and block storage.

Switch to the Auto Mode cluster:

```bash
$ prepare-environment fastpaths/getting-started
```
:::

Welcome to the first hands-on lab in the EKS workshop. The goal of this exercise is to familiarize ourselves with the sample application we'll use for many of the coming lab exercises and in doing so touch on some basic concepts related to deploying workloads to EKS. We'll explore the architecture of the application and deploy out the components to our EKS cluster.

Let's deploy your first workload to the EKS cluster in your lab environment and explore!
