---
title: "EKS Capabilities"
sidebar_position: 70
sidebar_custom_props: { "module": true }
---

::required-time

:::tip Before you start
This fast path uses a dedicated Amazon EKS Auto Mode cluster. The three labs use the EKS-managed forms of [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/), [Argo CD](https://argoproj.github.io/cd/), and [kro](https://kro.run/) — the controllers run in the AWS control plane, not on the worker nodes.

**One-time prerequisite (Lab 2 only):** the Argo CD capability authenticates through AWS IAM Identity Center, which requires a real human-facing user with a deliverable email and an MFA device. Walk through the [Identity Center prerequisite](./setup-idc.md) page first to create the admin group, then export its UUID:

```bash test=false
$ export ARGOCD_ADMIN_GROUP_ID=########-####-####-####-############
```

Prepare your environment for this fast path:

```bash timeout=1800
$ prepare-environment fastpaths/eks-capabilities
```

The first run takes a few minutes — it provisions the shared fastpaths infrastructure (KEDA, fluent-bit, External Secrets, Pod Identity for `carts`) plus the EKS capabilities and IAM Capability Roles for ACK, Argo CD, and KRO. Subsequent runs only re-deploy the base application.

This is the only place `prepare-environment` is invoked. The same provisioning is reused across all three labs.
:::

Welcome to the EKS Capabilities fast path. This is a 60-minute, three-lab journey targeted at the platform engineer / DevOps persona, showcasing the three capabilities that ship with [Amazon EKS Capabilities](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/) on a single coherent story over the retail sample application.

In this learning path, you'll learn:

- How to use the **ACK capability** to provision a real Amazon DynamoDB table from Kubernetes and migrate the `carts` microservice onto it.
- How to use the **Argo CD capability** to deliver the `catalog` microservice via GitOps from a pre-provisioned AWS CodeCommit repository.
- How to use the **kro capability** to declare the complete `carts` stack as a single `ResourceGraphDefinition` and observe its topologically-ordered reconciliation.

Each capability runs in AWS-managed infrastructure, so there's no Helm install, no controller Deployment to scale, and no Pod-level IRSA for the controllers — the capability itself assumes an IAM role to do its work.

Let's get started.
