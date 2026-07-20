---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Declarative, GitOps continuous delivery with Argo CD on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=120
$ prepare-environment automation/gitops/argocd
```

This will make the following changes to your lab environment:

- Create an AWS CodeCommit repository
- Create an IAM role for the EKS Capability for Argo CD
- Deploy the Amazon EKS Capability for Argo CD

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform).

:::

[Argo CD](https://argoproj.github.io/cd/) is a declarative continuous delivery tool for Kubernetes that implements GitOps principles. With the Amazon EKS Capability for Argo CD, the Argo CD runs in the AWS control plane — not on your worker nodes — giving you the full GitOps workflow without the operational overhead of installing, scaling, or maintaining Argo CD components yourself.

As a CNCF graduated project, Argo CD offers several key features:

- An intuitive web UI for deployment management
- Multi-cluster configuration support
- Integration with CI/CD pipelines
- Robust access controls
- Drift detection capabilities
- Support for various deployment strategies
- AWS-managed availability, scaling, and upgrades
- Native IAM Identity Center integration for SSO authentication

By using Argo CD, you can ensure that your Kubernetes applications remain consistent with their source configurations and automatically remediate any drift that occurs between the desired and actual states.
