---
title: "Continuous delivery with Argo CD"
sidebar_position: 20
---

::required-time

In [the ACK lab](../ack/) you provisioned an AWS resource from Kubernetes with the ACK capability. In this lab we'll change how an application gets _delivered_ to the cluster: instead of running `kubectl apply` by hand, we'll let the **Argo CD EKS capability** continuously reconcile the `catalog` service from a Git repository.

You can run Argo CD yourself, as shown in the [self-managed Argo CD lab](/docs/automation/gitops/argocd), where you `helm install argocd`, wait on an `argocd-server` LoadBalancer, and retrieve an initial admin secret. When you do, you also own the availability, scaling, patching, and upgrades of that control plane. This lab uses the Argo CD EKS capability instead. The control plane runs in AWS-managed infrastructure outside the cluster, AWS handles its operations, and it assumes an IAM Capability Role to pull from CodeCommit and to deploy into the cluster.

:::tip What's been set up for you

- The **Argo CD EKS-managed capability** is `ACTIVE` and federated with **AWS IAM Identity Center** for sign-in (there are no local users and no admin password).
- An **AWS CodeCommit repository** is pre-seeded with the `catalog` manifests, and the capability pulls from it using an IAM role, so there are no SSH keys or Git credentials to manage.
- `git-remote-codecommit` is pre-installed in the web IDE for cloning the repository.

:::

Throughout this lab, we will:

1. Verify the Argo CD capability is `ACTIVE` and the Argo CD API resources are present in the cluster.
2. Register the cluster as an Argo CD deployment target and create an `Application` that points at the seeded CodeCommit repository, with automated sync enabled.
3. Trigger a GitOps update by pushing a replica count change to CodeCommit and watching Argo CD roll it out automatically.

:::info
Every step below drives Argo CD through the Kubernetes API (`kubectl` against the `argoproj.io` resources), so the lab works without signing in. The Identity Center UI sign-in is an optional walkthrough if you want to explore the dashboard.
:::

## Verify the capability

Confirm the capability is `ACTIVE`:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ARGOCD_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

A capability transitions through `CREATING → ACTIVE`. If the status is anything other than `ACTIVE`, wait a moment and re-run the command.

Now confirm the Argo CD Custom Resource Definitions (CRDs) are registered in the cluster:

```bash
$ kubectl api-resources --api-group=argoproj.io
NAME             SHORTNAMES   APIVERSION                       NAMESPACED   KIND
applications     app,apps     argoproj.io/v1alpha1             true         Application
applicationsets  appset,as    argoproj.io/v1alpha1             true         ApplicationSet
appprojects      appproj,...  argoproj.io/v1alpha1             true         AppProject
```

The CRDs are here, but the Argo CD control plane is not. Confirm there is no Argo CD running on your nodes:

```bash
$ kubectl get pods -A | grep -i argocd || echo "No Argo CD pods in the cluster"
No Argo CD pods in the cluster
```

This is the whole point of a managed capability: in the self-managed Argo CD lab you would `helm install` argocd-server, repo-server, and a redis Pod, then own their upgrades and scaling. Here that entire control plane runs in AWS-owned infrastructure off your cluster. All you get inside the cluster are the CRDs, which you'll now use to declare Applications.
