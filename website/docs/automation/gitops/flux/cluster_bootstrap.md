
---
title: "Cluster bootstrap"
sidebar_position: 15
---

The bootstrap process installs Flux components on a cluster and creates the relevant files within the repository for managing cluster objects using GitOps with Flux.

Before bootstrapping a cluster, Flux allows us to run pre-bootstrap checks to verify that everything is set up correctly. Run the following command for Flux CLI to perform these checks:

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

- `--url`: Specifies the Git repository URL where Flux will store its state
- `--branch`: Indicates which Git branch this instance of Flux will use (important when following patterns with multiple branches in the same repo)
- `--components-extra`: Installs [additional toolkit components](https://fluxcd.io/flux/components/image/) needed for Continuous Integration features we'll use later
- `--private-key-file`: Tells Flux to use SSH for authenticating with the Git repository using the specified key

Let's verify that the bootstrap process completed successfully by checking the status of the kustomization:

```bash
$ flux get kustomization
NAME            REVISION        SUSPENDED       READY   MESSAGE
flux-system     main/6e6ae1d    False           True    Applied revision: main/6e6ae1d
```

The output confirms that Flux created the basic kustomization, and that it's successfully synchronized with the cluster. The `READY: True` status indicates that Flux has successfully applied the configuration from the Git repository to the cluster.
