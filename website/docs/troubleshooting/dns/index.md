---
title: "DNS Resolution"
sidebar_position: 60
chapter: true
sidebar_custom_props: { "module": true }
description: "Service communication is disrupted due to DNS resolution issues."
---

::required-time

In this lab, we will investigate a scenario where service communication is disrupted. We'll troubleshoot the networking issue and identify that the root cause is related to DNS resolution. Then we'll walk through essential troubleshooting steps to diagnose different types of DNS resolution failures, implement fixes, and restore service communication. For additional information about DNS troubleshooting in EKS, refer to [How do I troubleshoot DNS failures with Amazon EKS?](https://repost.aws/knowledge-center/eks-dns-failure)

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=10
$ prepare-environment troubleshooting/dns
```

The prepare-environment script for this module resets the workshop environment.
:::

### DNS resolution in EKS

In an EKS cluster, when applications need to connect to other services (either internal or external to the cluster), they must resolve the target endpoint name to an IP address through DNS.

By default, Kubernetes clusters configure all pods to use kube-dns service ClusterIP address as their name server. When you launch an Amazon EKS cluster, EKS deploys two pod replicas of CoreDNS to serve behind kube-dns service.

[CoreDNS](https://coredns.io/) is a flexible, extensible DNS server widely adopted as the standard Kubernetes cluster DNS.

Let's begin our troubleshooting journey in the next section.
