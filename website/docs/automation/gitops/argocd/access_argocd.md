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

## Activate your Argo CD user

An IAM Identity Center user `$ARGOCD_IDC_USER` has been created with ADMIN access to Argo CD. Before logging in you need to generate a one-time password for this user.

1. Open the [IAM Identity Center console](https://console.aws.amazon.com/singlesignon/home)
2. Navigate to **Users** and click on `argocd-admin@eksworkshop.com`
3. Click **Generate one-time password** and copy the password shown

:::info
This one-time password activation is required because IAM Identity Center users are created without a password. This is the same process an administrator would follow to onboard a new team member.
:::

## Accessing the Argo CD UI

Open `$ARGOCD_SERVER` in your browser and click **Log in via SSO**. Sign in with username `$ARGOCD_IDC_USER` and the one-time password you just copied. You will be prompted to set a new permanent password.

You will see an interface that looks like this:

![argocd-ui](/docs/automation/gitops/argocd/argocd-ui.webp)

## Authenticating the Argo CD CLI

To authenticate the Argo CD CLI, generate an **account token** from the Argo CD UI.

In the Argo CD UI, navigate to **Settings → Accounts → admin → Generate New Token**, copy the token, then set these environment variables:

```bash test=false
$ export ARGOCD_SERVER=$(echo $ARGOCD_SERVER | sed 's|^https://||')
$ export ARGOCD_AUTH_TOKEN="<paste-token-here>"
$ export ARGOCD_OPTS="--grpc-web"
```

Verify the CLI works:

```bash test=false
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
