---
title: Amazon EFS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Serverless, fully elastic file storage for workloads on Amazon Elastic Kubernetes Service with Amazon Elastic File System."
---
:::info Upcoming Live Workshop

Register for the **Building Modern Resilient Applications using Amazon EKS & Amazon EFS** Live Workshop

<LaunchButton url="https://aws-experience.com/amer/smb/e/f84b0/building-modern-resilient-applications-using-amazon-eks-and-amazon-efs" label="Book Now" />

:::
---
:::tip Before you start

Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/efs
```

This will make the following changes to your lab environment:

- Create an IAM role for the Amazon EFS CSI driver
- Create an Amazon EFS file system

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform).

:::

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) (Amazon EFS) provides a serverless, fully elastic file system that automatically scales on demand to petabytes without disrupting applications. It eliminates the need to provision and manage capacity as you add and remove files, making it ideal for use with AWS Cloud services and on-premises resources.

In this lab, you will:

- Learn about persistent network storage with the assets microservice
- Configure and deploy the EFS CSI Driver for Kubernetes
- Implement dynamic provisioning using EFS in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon EFS with Amazon EKS for scalable, persistent storage solutions.

