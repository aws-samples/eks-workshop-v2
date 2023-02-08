---
title: "Crossplane"
sidebar_position: 1
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[Crossplane](https://crossplane.io/) is an open source project in the CNCF that transforms your Kubernetes cluster into a universal control plane. Crossplane enables platform teams to assemble infrastructure from multiple vendors, and expose higher level self-service APIs for application teams to consume, without having to write any code.

Crossplane extends your Kubernetes cluster to support orchestrating any infrastructure or managed service. Compose Crossplane’s granular resources into higher level abstractions that can be versioned, managed, deployed and consumed using your favorite tools and existing processes. 

![EKS with RDS and MQ](./assets/eks-workshop-crossplane.jpg)
