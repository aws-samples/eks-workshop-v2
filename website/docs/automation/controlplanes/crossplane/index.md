---
title: "Crossplane"
sidebar_position: 1
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=120
$ prepare-environment automation/controlplanes/crossplane
```

This will make the following changes to your lab environment:

- Install Crossplane and the AWS provider in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/crossplane/.workshop/terraform).

:::

[Crossplane](https://crossplane.io/) is an open source project in the CNCF that transforms your Kubernetes cluster into a universal control plane. Crossplane enables platform teams to assemble infrastructure from multiple vendors, and expose higher level self-service APIs for application teams to consume, without having to write any code.
Crossplane extends your Kubernetes cluster to support orchestrating any infrastructure or managed service. Compose Crossplane’s granular resources into higher level abstractions that can be versioned, managed, deployed and consumed using your favorite tools and existing processes.

![EKS with Dynamodb](./assets/eks-workshop-crossplane.png)
