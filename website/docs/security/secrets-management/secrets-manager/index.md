---
title: "Managing Secrets with AWS Secrets Manager"
sidebar_position: 70
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment security/secrets-manager
```

This will make the following changes to your lab environment:

Install the following Kuberentes Addons in your EKS Cluter:
* Kubernetes Secrets Store CSI Driver
* AWS Secrets and Configuration Provider 

You can view the Terraform that applies these changes [here](https://github.com/aws-samples/eks-workshop-v2/tree/main/manifests/modules/security/secrets/secrets-manager/.workshop/terraform).

:::

AWS Secrets Manager (Secrets Manager) allows you to easily rotate, manage, and retrieve sensitive data such as credentials, API keys, certificates, among others. You can use AWS Secrets and Configuration Provider (ASCP) for Kubernetes Secrets Store CSI Driver to mount secrets stored in Secrets Manager as volumes in Kubernetes Pods.

With the ASCP, you can store and manage your secrets in Secrets Manager and then retrieve them through your workloads running on Amazon EKS. You can use IAM roles and policies to limit access to your secrets to specific Kubernetes Pods in a cluster. The ASCP retrieves the Pod identity and exchanges the identity for an IAM role. ASCP assumes the IAM role of the Pod, and then it can retrieve secrets from Secrets Manager that are authorized for that role.

If you use Secrets Manager automatic rotation for your secrets, you can also use the Secrets Store CSI Driver rotation reconciler feature to ensure you are retrieving the latest secret from Secrets Manager.

In this lab following section, we will create an example scenario of using secrets from AWS Secrets Manager.
