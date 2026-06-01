---
title: "Continuous delivery with Argo CD"
sidebar_position: 20
---

::required-time

:::tip What's been set up for you

- The **Argo CD EKS-managed capability** is `ACTIVE` on the cluster and federated with **AWS IAM Identity Center** for sign-in. There are no local users and no admin password — Identity Center is the only authentication path.
- The IAM Identity Center group whose UUID you provided as `ARGOCD_ADMIN_GROUP_ID` (see the [Identity Center prerequisite](./setup-idc.md)) is mapped to the Argo CD **ADMIN** role.
- An **AWS CodeCommit repository** (`${EKS_CAP_CODECOMMIT_REPO}`) is pre-provisioned and seeded with the `catalog` Kubernetes manifests.
- An **IAM Capability Role** trusted by the Argo CD capability service principal grants `codecommit:GitPull` on that repository — so the managed Argo CD can read your manifests with no SSH keys and no Git credentials.
- `git-remote-codecommit` is pre-installed in the web IDE for cloning the repo. The lab drives Argo CD through `kubectl` against the `argoproj.io` custom resources, with the browser UI available for interactive exploration.

:::

In [Lab 1](../ack/) you provisioned an AWS resource from Kubernetes with the ACK capability. In this lab we'll change how an application gets _delivered_ to the cluster: instead of running `kubectl apply` by hand, we'll let the **Argo CD EKS capability** continuously reconcile the `catalog` service from a Git repository.

Unlike the [self-managed Argo CD lab](/docs/automation/gitops/argocd), there's no `helm install argocd` step, no `argocd-server` LoadBalancer to wait on, and no initial admin secret to retrieve. The Argo CD control plane runs in AWS-managed infrastructure outside the cluster and assumes an IAM Capability Role to pull from CodeCommit and to deploy into the cluster.

Throughout this lab, we will:

1. Verify the Argo CD capability is `ACTIVE` and the Argo CD CRDs are present in the cluster.
2. Register the cluster as an Argo CD deployment target and create an `Application` that points at the seeded CodeCommit repository, with automated sync enabled.
3. Trigger a GitOps update by pushing an image tag change to CodeCommit and watching Argo CD roll it out automatically.

:::info
Authentication to the Argo CD UI is brokered through AWS Identity Center, which involves an interactive browser sign-in. So this lab can be tested end to end, every step below drives Argo CD through the Kubernetes API (`kubectl` against the `argoproj.io` custom resources). The Identity Center sign-in is covered as an optional walkthrough so you can explore the UI on your own.
:::
