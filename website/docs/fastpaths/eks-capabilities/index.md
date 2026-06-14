---
title: "EKS Capabilities"
sidebar_position: 70
sidebar_custom_props: { "module": true }
---

::required-time{estimatedLabExecutionTimeMinutes="25"}

Welcome to the **EKS Capabilities** fast path — a hands-on journey targeted at the platform engineer / DevOps persona, showcasing the capabilities that ship with [Amazon EKS Capabilities](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/) on a single coherent story over the retail sample application.

Each capability is a **fully managed control-plane component** — the controllers run in AWS-owned infrastructure, not on your worker nodes. There's no Helm install, no controller Deployment to scale, and no Pod-level IRSA for the controllers — the capability itself assumes an IAM role to do its work.

## What you'll build

| Lab | Capability | What you'll do |
|---|---|---|
| **Lab 1** | **ACK** | Provision a real Amazon DynamoDB table from Kubernetes by applying a `Table` custom resource, then migrate the `carts` microservice from its in-cluster mock to the AWS-managed table via EKS Pod Identity. |
| **Lab 2** | **Argo CD** | Deliver the `catalog` microservice via GitOps from a pre-provisioned AWS CodeCommit repository. Sign in to the managed Argo CD UI through AWS IAM Identity Center, register the cluster as a deployment target, then trigger a real GitOps update by pushing an image-tag bump. |
| **Lab 3** | **kro** | Compose Lab 1's three apply steps into a single `CartsStack` custom resource. Define a `ResourceGraphDefinition` that bundles a Namespace, an ACK `Table`, a ConfigMap, and a ServiceAccount, then apply one instance and watch kro reconcile the whole graph. |

## Before you start

This fast path uses a dedicated Amazon EKS Auto Mode cluster.

### One-time prerequisite (Lab 2 only)

The Argo CD capability authenticates **only** through AWS IAM Identity Center — there is no local admin user and no auto-generated password. Terraform creates the IDC user, group, and group-membership for you, but you'll do two one-time admin actions in the AWS Console to complete sign-in:

1. **Disable MFA** on the Identity Center instance (one-time, account-wide).
2. **Generate a one-time password** for the workshop's admin user.

Walk through the [Sign in to Argo CD via Identity Center](./argocd/signin-argocd.md) page when you reach Lab 2 — it's a 5-minute Console walk that disables MFA, generates a one-time password, and signs you in to Argo CD.

:::caution
Disabling MFA weakens security for **all** users in the IAM Identity Center instance. Acceptable for a personal/dev/test account; **do not** apply this in a production account or shared organization.
:::

### Provision the lab infrastructure

#### 1. Confirm Identity Center is enabled in this region

```bash test=false
$ aws sso-admin list-instances --query 'Instances[].InstanceArn' --output text | head -1
arn:aws:sso:::instance/ssoins-...
```

If that returns nothing, enable Identity Center once at the [IAM Identity Center console](https://console.aws.amazon.com/singlesignon/home) and re-run.

#### 2. Run `prepare-environment`

After completing the IDC prerequisite (or skip it if you only plan to do Lab 1):

```bash timeout=1800
$ prepare-environment fastpaths/eks-capabilities
```

The first run takes ~10 minutes — it provisions the shared fastpaths infrastructure (KEDA, fluent-bit, External Secrets, Pod Identity for `carts`) plus the EKS capabilities, IAM Capability Roles, the IAM Identity Center user/group/membership, and a seeded CodeCommit repository. Subsequent runs only re-deploy the base application.

This is the only place `prepare-environment` is invoked. The same provisioning is reused across all labs.

## What's pre-provisioned for you

By the end of `prepare-environment`, your cluster has:

- **ACK capability** — `ACTIVE`, with the DynamoDB controller's CRDs registered in the cluster.
- **Argo CD capability** — `ACTIVE`, federated with AWS IAM Identity Center for sign-in, with an admin group/user mapped to the Argo CD `ADMIN` role.
- **kro capability** — `ACTIVE`, with the `resourcegraphdefinitions.kro.run` CRD registered for use in Lab 3.
- **CodeCommit repository** — pre-seeded with the `catalog` Kubernetes manifests so Argo CD has something to reconcile from.
- **IAM Capability Roles** — one per capability, scoped to the AWS APIs each capability legitimately needs.
- **Pod Identity role for `carts`** — pre-provisioned and wildcard-scoped to `${EKS_CLUSTER_AUTO_NAME}-carts-*`, so the same role covers Lab 1's `-carts-fastpath` table and Lab 3's `-carts-kro` table without changes.
- **Shared fastpaths add-ons** — KEDA, fluent-bit, External Secrets (carried over from the developer/operator fastpaths preprovision).

Each capability runs in AWS-managed infrastructure outside the cluster — what you see inside the cluster is only the CRDs and any managed namespace each capability registers for you to apply against.

Let's get started.
