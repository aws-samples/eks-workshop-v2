---
title: 'Accessing AWS CodeCommit'
sidebar_position: 5
---

As AWS CodeCommit repository has been created in our lab environment, but we'll need to complete some steps before Cloud9 can connect to it.

We can add the SSH keys for CodeCommit to the known hosts file to prevent warnings later on:

```bash
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

And we can set up an identity that Git will use for our commits:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```