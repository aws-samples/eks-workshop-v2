
---
title: "Cluster Access Management API"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Manage AWS credentials using IAM Entities to provide access to Amazon Elastic Kubernetes Service for users and groups."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment security/cam
```

This will make the following changes to your lab environment:

- Create AWS IAM roles that will be assumed for the various scenarios

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/cam/.workshop/terraform).
:::

Platform engineering teams can now rely on a simplified configuration of AWS Identity and Access Management (IAM) users and roles with Kubernetes clusters, removing the burden from cluster administrators of having to maintain and integrate a separate identity provider. The integration between AWS IAM and Amazon EKS enables administrators to leverage IAM security features such as audit logging and multi-factor authentication by simply mapping IAM to Kubernetes identities. This allows administrators to fully define authorized IAM principals and their associated Kubernetes permissions directly through an EKS API during or after cluster creation.

In this chapter you'll understand how the Cluster Access Management API works and learn how to translate the existing identity mapping controls to the new model to provide authentication and authorization to Amazon EKS clusters in a seamless way.
