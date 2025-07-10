---
title: "Managing secrets with AWS Secrets Manager"
sidebar_position: 420
sidebar_custom_props: { "module": true }
description: "Provide sensitive configuration like credentials to applications running on Amazon Elastic Kubernetes Service with AWS Secrets Manager."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=30 hook=install
$ prepare-environment security/secrets-manager
```

This will make the following changes to your lab environment:

Install the following Kubernetes addons in your EKS Cluster:

- Kubernetes Secrets Store CSI Driver
- AWS Secrets and Configuration Provider
- External Secrets Operator

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/secrets-manager/.workshop/terraform).

:::

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) is a service that enables you to easily rotate, manage, and retrieve sensitive data including credentials, API keys, and certificates. Using the [AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws) with the [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/), you can mount secrets stored in Secrets Manager as volumes in Kubernetes Pods.

ASCP allows workloads running on Amazon EKS to access secrets stored in Secrets Manager through fine-grained access control using IAM roles and policies. When a Pod requests access to a secret, ASCP retrieves the Pod's identity, exchanges it for an IAM role, assumes that role, and then retrieves only the secrets authorized for that role from Secrets Manager.

An alternative approach for integrating AWS Secrets Manager with Kubernetes is through [External Secrets](https://external-secrets.io/). This operator synchronizes secrets from AWS Secrets Manager into Kubernetes Secrets, managing the entire lifecycle through an abstraction layer. It automatically injects values from Secrets Manager into Kubernetes Secrets.

Both approaches support automatic secret rotation through Secrets Manager. When using External Secrets, you can configure a refresh interval to poll for updates, while the Secrets Store CSI Driver provides a rotation reconciler feature to ensure Pods always have the latest secret values.

In the following sections, we'll explore practical examples of managing secrets using both AWS Secrets Manager with ASCP and External Secrets.
