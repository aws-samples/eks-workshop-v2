---
title: "Git repository"
sidebar_position: 5
---

Argo CD applies the GitOps methodology to Kubernetes, using Git repositories as the single source of truth for defining the desired application state. With Argo CD, you can deploy applications, monitor their health, and automatically synchronize them with the desired state. Kubernetes manifests can be specified in several ways:

- Kubernetes YAML files
- Kustomize applications
- Helm charts
- Jsonnet files

For our lab environment, an AWS CodeCommit repository has been provisioned. However, we need to complete a few setup steps before our IDE can connect to it.

First, let's add the SSH keys for CodeCommit to the known hosts file to prevent SSH warnings during future operations:

```bash hook=ssh
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

Now, let's configure Git with a user identity for our commits:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

Next, let's clone the repository and set up the initial structure:

```bash
$ git clone $GITOPS_REPO_URL_ARGOCD ~/environment/argocd
$ git -C ~/environment/argocd checkout -b main
Switched to a new branch 'main'
$ touch ~/environment/argocd/.gitkeep
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Initial commit"
$ git -C ~/environment/argocd push --set-upstream origin main
```

With these steps completed, we've established our Git repository that will serve as the foundation for our GitOps workflow with Argo CD.
