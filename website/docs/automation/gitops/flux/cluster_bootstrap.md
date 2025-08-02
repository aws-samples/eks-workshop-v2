---
title: "Cluster bootstrap"
sidebar_position: 15
---

The bootstrap process installs Flux components on a cluster and creates the relevant files within the repository for managing clusters object using GitOps with Flux.

Before bootstrapping a cluster, Flux allows us to run pre-bootstrap checks to verify that everything is set up correctly. Run the following command for Flux CLI to perform the checks:

```bash
$ flux check --pre
> checking prerequisites
...
> prerequisites checks passed
```

Now let's bootstrap Flux on our EKS cluster using the CodeCommit repository:

```bash
$ flux bootstrap git \
  --url=ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops \
  --branch=main \
  --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
  --components-extra=image-reflector-controller,image-automation-controller \
  --network-policy=false \
  --silent
```

Let's break down the command above:

- First we tell Flux which Git repository to use to store its state
- After that, we're passing the Git `branch` that we want this instance of Flux to use, since some patterns involve multiple branches in the same Git repository
- We use the `--components-extra` parameter to install [additional toolkit components](https://fluxcd.io/flux/components/image/) that we'll use in the Continuous Integration section
- Finally we'll be using SSH for Flux to connect and authenticate using the SSH key at `/home/ec2-user/gitops_ssh.pem`

Now, let's verify that the bootstrap process completed successfully by running the following command:

```bash
$ flux get kustomization
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:6e6ae1d   False        True    Applied revision: main@sha1:6e6ae1d
```

That shows that Flux created the basic kustomization, and that it's in sync with the cluster.
