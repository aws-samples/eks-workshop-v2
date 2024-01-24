---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

This will make the following changes to your lab environment:
- Create an AWS CodeCommit repository
- Create an IAM user with access to the CodeCommit repository
- Create a Continuous Integration pipeline for the [sample application UI component](https://github.com/aws-containers/retail-store-sample-app)

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/custom-networking/.workshop/terraform).

:::

Flux keeps Kubernetes clusters in sync with configuration kept under source control like Git repositories, and automates updates to that configuration when there is new code to deploy. It's built using Kubernetes’ API extension server, and can integrate with Prometheus and other core components of the Kubernetes ecosystem. Flux supports multi-tenancy and syncs an arbitrary number of Git repositories.
