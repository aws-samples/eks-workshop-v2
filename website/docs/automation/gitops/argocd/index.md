---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Declarative, GitOps continuous delivery with Argo CD on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=120
$ prepare-environment automation/gitops/argocd
```

This will make the following changes to your lab environment:

- Install the AWS Load Balancer controller in the Amazon EKS cluster
- Install the EKS managed addon for the EBS CSI driver

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform).

:::

[Argo CD](https://argoproj.github.io/cd/) is a declarative continuous delivery tool for Kubernetes that implements GitOps principles. It operates as a controller within your cluster, continuously monitoring Git repositories for changes and automatically synchronizing applications to match the desired state defined in your Git repository.

As a CNCF graduated project, Argo CD offers several key features:

- An intuitive web UI for deployment management
- Multi-cluster configuration support
- Integration with CI/CD pipelines
- Robust access controls
- Drift detection capabilities
- Support for various deployment strategies

By using Argo CD, you can ensure that your Kubernetes applications remain consistent with their source configurations and automatically remediate any drift that occurs between the desired and actual states.
