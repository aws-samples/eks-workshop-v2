---
title: "Cluster bootstrap"
sidebar_position: 15
---

An AWS CodeCommit repository has already been created for you and Argo CD has already been deployed to the EKS cluster so let's create necessary Argo CD components for our application.

Create an Argo CD `Application`:

```file
automation/gitops/argocd-codecommit/application/application.yaml
```

Let's break down the manifest above:

- First we tell ArgoCD what will be the `name` of our application
- After that we define which Git repository `source` to use to get the desired state of our application. We define `repoUrl` of the AWS CodeCommit repository, a repository branch with `targetRevision`
- Finally we define a `path` to application manifests within the repository

Copy the existing kustomize configuration for the Argo CD application:

```bash
$ mkdir -p ~/environment/argocd-application
$ cp -R /workspace/modules/automation/gitops/argocd-codecommit/application/* ~/environment/argocd-application
```

Let's apply the kustomization:

```bash
$ GITOPS_REPO_URL=ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops-argocd
$ echo $GITOPS_REPO_URL > ~/environment/argocd-application/gitops_repo_url
$ kubectl apply -k ~/environment/argocd-application
application.argoproj.io/apps created
```

Create an Argo CD repository `Secret` to store `sshPrivateKey` for access to an AWS Codecommit repository `url`:

```bash
$ kubectl -n argocd delete secret codecommit-repo --ignore-not-found && \
kubectl -n argocd create secret generic codecommit-repo \
--from-literal=type=git \
--from-literal=insecure="true" \
--from-literal=url="${GITOPS_REPO_URL}" \
--from-file=sshPrivateKey=${HOME}/.ssh/gitops_ssh.pem \
&& kubectl -n argocd label secret codecommit-repo "argocd.argoproj.io/secret-type=repository"
secret/codecommit-repo created
secret/codecommit-repo labeled
```
