---
title: "Managing Secrets with AWS Secrets Manager"
sidebar_position: 420
sidebar_custom_props: { "module": true }
---

{{% required-time %}}

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

You can view the Terraform that applies these changes [here](https://github.com/aws-samples/eks-workshop-v2/tree/main/manifests/modules/security/secrets/secrets-manager/.workshop/terraform).

:::

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) allows you to easily rotate, manage, and retrieve sensitive data such as credentials, API keys, certificates, among others. You can use [AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws) for [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) to mount secrets stored in Secrets Manager as volumes in Kubernetes Pods.

With the ASCP, you can store and manage your secrets in Secrets Manager and then retrieve them through your workloads running on Amazon EKS. You can use IAM roles and policies to limit access to your secrets to specific Kubernetes Pods in a cluster. The ASCP retrieves the Pod identity and exchanges the identity for an IAM role. ASCP assumes the IAM role of the Pod, and then it can retrieve secrets from Secrets Manager that are authorized for that role.

Another way to integrate AWS Secrets Manager with Kubernetes Secrets, is through [External Secrets](https://external-secrets.io/). External Secrets is an operator that can integrate and synchronize secrets from AWS Secrets Manager reading the information from it and automatically injecting the values into a Kubernetes Secret with an abstraction that stores and manages the lifecycle of the secrets for you.

If you use Secrets Manager automatic rotation for your secrets, you can rely on External Secrets refresh interval or use the Secrets Store CSI Driver rotation reconciler feature to ensure you are retrieving the latest secret from Secrets Manager, depending on the tool you choose to manage secrets inside your Amazon EKS Cluster.

In this lab following section, we will create a couple of example scenarios of using secrets from AWS Secrets Manager and External Secrets.
