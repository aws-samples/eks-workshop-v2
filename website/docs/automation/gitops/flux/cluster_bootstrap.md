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

Now we can bootstrap Flux on our EKS cluster using a Gitea repository:

```bash
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ flux bootstrap git \
   --url=ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/flux.git \
   --branch=main \
   --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
   --network-policy=false --silent
```

Let's break down the command above:

- First we tell Flux which Git repository to use to store its state
- After that, we're passing the Git `branch` that we want this instance of Flux to use, since some patterns involve multiple branches in the same Git repository
- We provide authentication credentials, and instruct Flux to use these to authenticate to Git instead of using SSH
- Finally we provide some configuration to simplify the setup specifically for this workshop

:::caution

The above approach to install Flux is NOT suitable for production and the [official documentation](https://fluxcd.io/flux/installation/) should be followed in its place for that situation.

:::

Now, let's verify that the bootstrap process completed successfully by running the following command:

```bash
$ flux get kustomization
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:6e6ae1d   False        True    Applied revision: main@sha1:6e6ae1d
```

That shows that Flux created the basic kustomization, and that it's in sync with the cluster.
