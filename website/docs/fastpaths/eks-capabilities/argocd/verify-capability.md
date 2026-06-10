---
title: "Verify the Argo CD capability"
sidebar_position: 20
---

The `prepare-environment` step has already enabled the Argo CD capability on the cluster and federated it with AWS Identity Center. Before deploying anything, let's confirm it's `ACTIVE` and that the Argo CD custom resources are available.

Inspect the capability resource directly:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ARGOCD_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

A capability transitions through `CREATING → ACTIVE`. If the status here is anything other than `ACTIVE`, wait a moment and re-run the command — the capability may still be initializing.

The capability publishes the URL of its managed Argo CD server. It was exported into your shell as `$EKS_CAP_ARGOCD_URL`:

```bash
$ echo $EKS_CAP_ARGOCD_URL
https://....argocd.eks.amazonaws.com
```

Now check that the Argo CD controller's custom resources are registered in the cluster:

```bash
$ kubectl api-resources --api-group=argoproj.io
NAME             SHORTNAMES   APIVERSION                       NAMESPACED   KIND
applications     app,apps     argoproj.io/v1alpha1             true         Application
applicationsets  appset,as    argoproj.io/v1alpha1             true         ApplicationSet
appprojects      appproj,...  argoproj.io/v1alpha1             true         AppProject
```

:::info
Just like the ACK capability, we never installed a Helm chart and there's no `argocd-server` Pod running on your worker nodes. The Argo CD control plane runs in AWS-managed infrastructure outside the cluster — what you see inside the cluster are the CRDs the capability registered, which you'll use to declare Applications.
:::

The capability is also federated with the Identity Center group (its UUID — see [Sign in to Argo CD via Identity Center](./signin-argocd.md)) that grants the Argo CD `ADMIN` role:

```bash
$ echo $EKS_CAP_ARGOCD_ADMIN_GROUP_ID
########-####-####-####-############
```

With the capability `ACTIVE` and the CRDs in place, we're ready to deliver the `catalog` service via GitOps.
