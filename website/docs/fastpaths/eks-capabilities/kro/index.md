---
title: "Compose stacks with kro"
sidebar_position: 30
---

::required-time{estimatedLabExecutionTimeMinutes="4"}

In [the ACK lab](../ack/) you applied **three separate manifests** (a `Table` resource, a ConfigMap override, and a Pod Identity association) to migrate `carts` onto an AWS-managed DynamoDB table. That's the right altitude for a one-off, but a platform team running this for many services would want **one user-facing resource** that captures the whole stack.

In this lab you'll do exactly that with **kro (Kube Resource Orchestrator)**, delivered as an EKS capability. kro lets a platform team package many Kubernetes resources behind one simple, custom resource. There are two pieces:

- A **`ResourceGraphDefinition` (RGD)** is the blueprint. It defines a new custom resource type (here, `CartsStack`), the handful of inputs it accepts (like a table name), and the graph of underlying resources one instance expands into: a Namespace, an ACK `Table`, a ConfigMap, a ServiceAccount, a Deployment, and a Service. A platform team writes this once.
- An **instance** is what everyone else applies: a short `CartsStack` resource with just the inputs filled in. kro reads it and creates the whole graph for you, in the right order.

Like the other capabilities, kro's controllers run in AWS-owned infrastructure outside the cluster with AWS handling their operations. Inside the cluster you only see the Custom Resource Definitions (CRDs) it registers, starting with `resourcegraphdefinitions.kro.run`.

:::tip What's been set up for you

- The **kro EKS-managed capability** is `ACTIVE` on the cluster, with the `resourcegraphdefinitions.kro.run` CRD registered.
- The **ACK DynamoDB capability** from the ACK lab is still `ACTIVE`, so kro will compose its `Table` resource alongside native Kubernetes objects.
- The pre-provisioned `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` IAM role is wildcard-scoped to `${EKS_CLUSTER_AUTO_NAME}-carts-*` tables, so the same role covers the ACK lab's `-carts-fastpath` table and the kro lab's `-carts-kro` table without changes.

:::

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
kro only reconciles Kubernetes resources; it never calls AWS APIs itself. The AWS DynamoDB table in the graph above is created by the ACK controller from the ACK lab, which kro drives by creating the `Table` resource.
:::

## Verify the capability

Confirm the capability is `ACTIVE`:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_KRO_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

Now look at the CRD kro registered, which is the RGD "blueprint" type from above:

```bash
$ kubectl api-resources --api-group=kro.run
NAME                       SHORTNAMES   APIVERSION         NAMESPACED   KIND
resourcegraphdefinitions   rgd          kro.run/v1alpha1   false        ResourceGraphDefinition
```

Note `NAMESPACED: false`: an RGD is **cluster-scoped**, because the blueprint is shared across the whole cluster. The instances you create from it (your `CartsStack` resources) are namespaced, since each one owns resources in a specific namespace. With the capability `ACTIVE` and the RGD CRD in place, we're ready to define our first RGD.
