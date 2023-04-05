---
title: 'Accessing AWS CodeCommit'
sidebar_position: 10
---

As AWS CodeCommit repository has been created in our lab environment, but we'll need to configure out Cloud9 instance to connect to it.

First download the SSH key to be used to authenticate, which has been stored in an encrypted SSM parameter:

```bash
$ mkdir -p ~/.ssh
$ aws ssm get-parameter --name ${GITOPS_SSH_SSM_NAME} --with-decryption \
  --query 'Parameter.Value' \
  --output text > ~/.ssh/gitops_ssh.pem
$ chmod 400 ~/.ssh/gitops_ssh.pem
```

Then we'll add a configuration file that instructs SSH to use that SSH key to connect to CodeCommit repositories:

```bash
$ cat <<EOF > ~/.ssh/config
Host git-codecommit.*.amazonaws.com
  User ${GITOPS_IAM_SSH_USER}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOF
$ chmod 600 ~/.ssh/config
```

We can add the SSH keys for CodeCommit to the known hosts file to prevent warnings later on:

```bash
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com >> ~/.ssh/known_hosts
```

And finally we can set up an identity that Git will use for our commits:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```