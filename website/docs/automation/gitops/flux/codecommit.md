---
title: "Git repository"
sidebar_position: 5
---

Flux applies the GitOps methodology to Kubernetes, using Git repositories as the single source of truth for defining the desired application state. Flux keeps a cluster in sync with the configuration stored in Git and automatically reconciles any changes that get pushed.

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

With these steps completed, we've established our Git repository that will serve as the foundation for our GitOps workflow with Flux.
