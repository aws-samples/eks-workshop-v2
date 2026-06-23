---
title: "Compose stacks with kro"
sidebar_position: 30
---

::required-time{estimatedLabExecutionTimeMinutes="4"}

:::tip What's been set up for you

- The **kro EKS-managed capability** is `ACTIVE` on the cluster, with the `resourcegraphdefinitions.kro.run` CRD registered.
- The **ACK DynamoDB capability** from Lab 1 is still `ACTIVE` — kro will compose its `Table` custom resource alongside native Kubernetes objects.
- The pre-provisioned `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` IAM role is wildcard-scoped to `${EKS_CLUSTER_AUTO_NAME}-carts-*` tables, so the same role covers Lab 1's `-carts-fastpath` table and Lab 3's `-carts-kro` table without changes.

:::

In [Lab 1](../ack/) you applied **three separate manifests** — a `Table` custom resource, a ConfigMap override, and a Pod Identity association — to migrate `carts` onto an AWS-managed DynamoDB table. That's the right altitude for a one-off, but a platform team running this for many services would want **one user-facing CR** that captures the whole stack.

In this lab you'll do exactly that with the **kro** EKS capability. kro lets you define a `ResourceGraphDefinition` (RGD) — a schema for a higher-level CR plus the graph of resources it expands into — and apply a single instance that bundles a Namespace, an ACK `Table`, a ConfigMap, and a ServiceAccount. The kro controllers run in AWS-owned infrastructure outside the cluster; you only see the CRDs they registered.

Throughout this lab, we will:

1. Verify the kro capability is `ACTIVE` and the `resourcegraphdefinitions.kro.run` CRD is present.
2. Apply a `CartsStack` ResourceGraphDefinition that composes Namespace + ACK Table + ConfigMap + ServiceAccount + Deployment + Service.
3. Apply a `CartsStack` instance, observe kro reconcile its child resources in order, then bind a Pod Identity association so the `carts` Pod can read and write the new table.

A single `CartsStack` apply produces this graph:

```text
                you apply:
                CartsStack/carts-kro          (one CR, two required fields)
                       │
                       ▼  kro reconciler expands the RGD
                       │
   ┌──────────┬────────┴──┬──────────┬─────────────┬──────────┐
   ▼          ▼           ▼          ▼             ▼          ▼
Namespace   Table     ConfigMap     SA        Deployment    Service
                        │                          │
                        ▼                          ▼
                   ACK DynamoDB                 Pod (carts-…)
                    controller                       │
                        │                            │ + aws eks create-pod-identity-association
                        ▼                            ▼
                AWS DynamoDB table          AWS_CONTAINER_CREDENTIALS
                (eks-workshop-…-carts-kro)   via Pod Identity Agent
```

:::info
kro itself does not call AWS APIs — it only reconciles Kubernetes resources. Anything that needs to _create_ an AWS resource flows through a controller that does (in this lab, the ACK DynamoDB controller from Lab 1). Pod Identity is an EKS API rather than a Kubernetes API, so the binding step at the end of this lab is a one-line `aws eks` command, not part of the RGD.
:::
