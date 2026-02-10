---
title: "Crossplane"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Build a cloud native control plane with Crossplane on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=120
$ prepare-environment automation/controlplanes/crossplane
```

This will make the following changes to your lab environment:

- Install Crossplane and the AWS provider in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/crossplane/.workshop/terraform).

:::

[Crossplane](https://crossplane.io/) is an open-source project in the Cloud Native Computing Foundation (CNCF) that transforms your Kubernetes cluster into a universal control plane. It enables platform teams to assemble infrastructure from multiple vendors and expose higher-level self-service APIs for application teams to consume, without writing any code.

Crossplane extends your Kubernetes cluster to support orchestrating any infrastructure or managed service. It allows you to compose Crossplane's granular resources into higher-level abstractions that can be versioned, managed, deployed, and consumed using your favorite tools and existing processes.

![EKS with Dynamodb](/docs/automation/controlplanes/crossplane/eks-workshop-crossplane.webp)

With Crossplane, you can:

1. Provision and manage cloud infrastructure directly from your Kubernetes cluster
2. Define custom resources that represent complex infrastructure setups
3. Create abstraction layers that simplify infrastructure management for application developers
4. Implement consistent policies and governance across multiple cloud providers

In this module, we'll explore how to use Crossplane to manage AWS resources, specifically focusing on provisioning and configuring a DynamoDB table for our sample application.
