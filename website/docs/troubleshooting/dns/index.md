---
title: "DNS resolution scenario"
sidebar_position: 20
chapter: true
sidebar_custom_props: { "module": true }
description: "Service communication is disrupted due to DNS resolution issues."
---

::required-time

In this lab we will face a scenario where service communication is disrupted. We will troubleshoot the cause of this networking issue and narrow it down until we identify the problem to be related to DNS resolution. Then we will cover important troubleshooting steps that will help us identify what is causing DNS resolution to fail. We will fix the problem and ensure that service communication is restored. To get more further details about DNS troubleshooting in EKS, please check this troublhsooting guide about [How do I troubleshoot DNS failures with Amazon EKS?](https://repost.aws/knowledge-center/eks-dns-failure)

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=5
$ prepare-environment troubleshooting/dns
```

:::

### DNS resolution in EKS

When an application running in an EKS cluster tries to connect to another service, internal or external, it must translate the target endpoint name to an IP address. This translation is called DNS resolution.

By default, Kubernetes clusters configure all pods to use kube-dns service ClusterIP address as its nameserver. When you launch an Amazon EKS cluster, EKS deploys two pod replicas of CoreDNS pods to serve the cluster kube-dns service.

[CoreDNS](https://coredns.io/) is a flexible, extensible DNS server that is commonly used as the Kubernetes cluster DNS.

