---
title: "Cluster bootstrap"
sidebar_position: 15
---

The bootstrap process installs Flux components on a cluster and creates the relevant files within the repository for managing clusters object using GitOps with Flux.

Before bootstrapping a cluster, Flux allows us to run pre-bootstrap checks to verify that everything is set up correctly. Run the following command for Flux CLI to perform the checks:

```bash
$ flux check --pre
> checking prerequisites
> Kubernetes VAR::KUBERNETES_NODE_VERSION >=1.20.6-0
> prerequisites checks passed
```

Now let's bootstrap Flux on our EKS cluster using the CodeCommit repository:

```bash
$ flux bootstrap git \
  --url=ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops \
  --branch=main \
  --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
  --network-policy=false \
  --silent
```

Let's break down the command above:

- First we tell Flux which Git repository to use to store its state
- After that, we're passing the Git `branch` that we want this instance of Flux to use, since some patterns involve multiple branches in the same Git repository
- Finally we'll be using SSH for Flux to connect and authenticate using the SSH key at `/home/ec2-user/gitops_ssh.pem`

Now, let's verify that the bootstrap process completed successfully by running the following command:

```bash
$ flux get kustomization
NAME            REVISION        SUSPENDED       READY   MESSAGE
flux-system     main/6e6ae1d    False           True    Applied revision: main/6e6ae1d
```

That shows that Flux created the basic kustomization, and that it's in sync with the cluster.
