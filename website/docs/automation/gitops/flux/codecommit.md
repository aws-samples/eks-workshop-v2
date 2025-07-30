
---
title: "Accessing AWS CodeCommit"
sidebar_position: 5
---

An AWS CodeCommit repository has been created in our lab environment, but we need to complete some configuration steps before our web IDE can connect to it.

First, let's add the SSH keys for CodeCommit to the known hosts file to prevent SSH warnings later on:

```bash
$ mkdir -p ~/.ssh/
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

Next, we'll set up an identity that Git will use for our commits:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
```

These configurations will allow us to interact with the CodeCommit repository smoothly throughout the module.
