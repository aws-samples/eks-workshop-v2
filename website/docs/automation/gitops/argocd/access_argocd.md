---
title: "Accessing Argo CD"
sidebar_position: 10
weight: 10
---

:::tip What's been set up for you
The **Amazon EKS Capability for Argo CD** has been enabled on your cluster. Argo CD runs in the AWS control plane — there are no Argo CD pods on your worker nodes. An **AWS IAM Identity Center** user has been created with ADMIN access to Argo CD.
:::

Let's retrieve the Argo CD server URL:

```bash
$ export ARGOCD_SERVER=$(aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_NAME \
  --capability-name argocd \
  --query 'capability.configuration.argoCd.serverUrl' \
  --output text)
$ echo "Argo CD URL: $ARGOCD_SERVER"
Argo CD URL: https://abcd1234.eks-capabilities.us-west-2.amazonaws.com
```

## Your Argo CD sign-in

Retrieve the credentials for the IAM Identity Center user that has ADMIN access to Argo CD:

```bash
$ echo "User:     $ARGOCD_IDC_USER"
$ echo "Password: $ARGOCD_IDC_PASSWORD"
```

The environment setup already activated this user and stored its password, so both lines print a value.

## Accessing the Argo CD UI

Open `$ARGOCD_SERVER` in your browser and click **Log in via SSO**, then sign in as `$ARGOCD_IDC_USER`.

You will see an interface that looks like this:

![argocd-ui](/docs/automation/gitops/argocd/argocd-ui.webp)

## Authenticating the Argo CD CLI

The capability does not support `argocd login`, so instead of signing in, the CLI authenticates with an **account token** that you generate in the UI:

1. In the Argo CD UI you opened above, go to **Settings → Accounts → admin**
2. Choose **Generate New Token**
3. Copy the token it shows you, as it is not displayed again

Then point the CLI at the capability:

```bash
$ export ARGOCD_SERVER=$(echo $ARGOCD_SERVER | sed 's|^https://||')
$ export ARGOCD_OPTS="--grpc-web"
```

The capability reports its endpoint as a URL, but the CLI expects a bare host, which is what the first line strips. `--grpc-web` is needed because the capability serves the API over gRPC-Web.

Now give the CLI your token, pasting it in place of the placeholder:

```bash test=false
$ export ARGOCD_AUTH_TOKEN="<paste-token-here>"
```

With these three set, the CLI works without `argocd login`.

Verify the CLI works:

```bash
$ argocd app list
NAME  CLUSTER  NAMESPACE  PROJECT  STATUS  HEALTH  SYNCPOLICY  CONDITIONS
```

## Registering the EKS Cluster

Unlike a self-managed Argo CD installation (which runs inside the cluster and has direct API server access), the EKS Capability runs in the AWS control plane outside your cluster. You need to explicitly register your EKS cluster so Argo CD knows how to deploy applications to it.

```bash
$ export CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME \
  --query 'cluster.arn' --output text)
$ argocd cluster add default --aws-cluster-name $CLUSTER_ARN --yes
INFO[0000] ServiceAccount "argocd-manager" created in namespace "kube-system"
INFO[0000] ClusterRole "argocd-manager-role" created
INFO[0000] ClusterRoleBinding "argocd-manager-role-binding" created
Cluster 'arn:aws:eks:us-west-2:...' added
```

This creates an `argocd-manager` ServiceAccount in `kube-system` that Argo CD uses to deploy and manage application resources on the cluster. The cluster is identified by its ARN — you'll use `$CLUSTER_ARN` as the destination server when creating Argo CD applications.

## Registering the Git Repository

Register the CodeCommit Git repository with Argo CD:

```bash
$ argocd repo add $GITOPS_REPO_URL_ARGOCD \
  --ssh-private-key-path ${HOME}/.ssh/gitops_ssh.pem \
  --insecure-ignore-host-key --upsert --name git-repo
Repository 'ssh://...' added
```
