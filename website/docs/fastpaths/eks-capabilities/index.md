---
title: "Capability Essentials"
sidebar_position: 70
sidebar_custom_props: { "module": true }
---

::required-time{estimatedLabExecutionTimeMinutes="14"}

:::tip Before you start
This fast path uses a dedicated Amazon EKS Auto Mode cluster. Amazon EKS Auto Mode extends AWS management of Kubernetes clusters beyond the cluster itself, managing infrastructure that enables smooth operation of your workloads including compute autoscaling, networking, load balancing, DNS, and block storage.

Prepare your environment for this lab:

```bash timeout=1800
$ prepare-environment fastpaths/eks-capabilities
```

This provisions three managed capabilities and their supporting infrastructure, so it takes roughly 7 to 10 minutes. It is normal for the command to appear idle while the capabilities activate.
:::

Welcome to **Capability Essentials**, a hands-on fast path targeted at the platform engineer and DevOps persona. It tells a single coherent story over the retail sample application using the capabilities that ship with [Amazon EKS Capabilities](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/).

Each capability is a fully managed control-plane component. The controllers run in AWS-owned infrastructure separate from your cluster, not on your worker nodes, and AWS handles their scaling, patching, and upgrades. There is no Helm install, no controller Deployment to scale, and no Pod-level IRSA for the controllers, because the capability itself assumes an IAM role to do its work.

:::info
Amazon EKS Capabilities offload the operation of platform components to AWS so you can focus on deploying applications rather than maintaining platform infrastructure. Learn more in the [Amazon EKS Capabilities announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/).
:::

## What you'll build

| Capability  | What you'll do                                                                                                                                                                                                                                                                  |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ACK** (AWS Controllers for Kubernetes) | Provision a real Amazon DynamoDB table from Kubernetes by applying a `Table` resource, then migrate the `carts` microservice from its in-cluster mock to the AWS-managed table via EKS Pod Identity.                                                                     |
| **Argo CD** | Deliver the `catalog` microservice via GitOps from a pre-provisioned AWS CodeCommit repository. Sign in to the managed Argo CD UI through AWS IAM Identity Center, register the cluster as a deployment target, then trigger a real GitOps update. |
| **kro** (Kube Resource Orchestrator) | Compose the ACK lab's three apply steps into a single `CartsStack` resource. Define a `ResourceGraphDefinition` that bundles a Namespace, an ACK `Table`, a ConfigMap, and a ServiceAccount, then apply one instance and watch kro reconcile the whole graph.                  |

The Argo CD lab signs in through AWS IAM Identity Center and includes a short, one-time console setup, covered on its [Sign in to Argo CD via Identity Center](./argocd/signin-argocd.md) page.

## What's pre-provisioned for you

By the end of `prepare-environment`, your cluster has:

| Resource | State |
| --- | --- |
| **ACK capability** | `ACTIVE`, with the DynamoDB controller's Custom Resource Definitions (CRDs) registered in the cluster |
| **Argo CD capability** | `ACTIVE`, federated with AWS IAM Identity Center for sign-in, with an admin group and user mapped to the Argo CD `ADMIN` role |
| **kro capability** | `ACTIVE`, with the `resourcegraphdefinitions.kro.run` CRD registered for use in the kro lab |
| **CodeCommit repository** | Pre-seeded with the `catalog` Kubernetes manifests so Argo CD has something to reconcile from |
| **IAM Capability Roles** | One per capability, scoped to the AWS APIs each capability needs |
| **Pod Identity role for `carts`** | Wildcard-scoped to `${EKS_CLUSTER_AUTO_NAME}-carts-*`, so the same role covers the ACK lab's `-carts-fastpath` table and the kro lab's `-carts-kro` table without changes |
| **Shared fast path add-ons** | KEDA, fluent-bit, and External Secrets, carried over from the developer and operator fast path preprovision |

Each capability runs in AWS-managed infrastructure outside the cluster. What you see inside the cluster is only the CRDs and any managed namespace each capability registers for you to apply against.

Let's get started.
