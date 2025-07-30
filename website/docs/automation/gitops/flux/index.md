
---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: { "module": true }
description: "Implement continuous and progressive delivery with Flux on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

This will make the following changes to your lab environment:

- Create an AWS CodeCommit repository
- Create an IAM user with access to the CodeCommit repository

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/flux/.workshop/terraform).
:::

Flux is a GitOps tool that keeps Kubernetes clusters in sync with configuration stored in Git repositories. It automatically updates your cluster configuration when new code is pushed to your repository. Flux is built using Kubernetes' API extension server and integrates with core components of the Kubernetes ecosystem like Prometheus. It supports multi-tenancy and can sync an arbitrary number of Git repositories to your cluster.

In this module, you'll learn how to implement continuous delivery with Flux on Amazon EKS by bootstrapping Flux on your cluster and deploying an application using GitOps principles.
