---
title: Workload storage with Amazon EFS
sidebar_position: 40
description: "Serverless, fully elastic file storage for workloads on Amazon Elastic Kubernetes Service with Amazon Elastic File System."
---

:::tip What's been set up for you
The environment preparation stage made the following changes to your lab environment:

- Create an IAM role for the Amazon EFS CSI driver
- Create an Amazon EFS file system

:::

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) (Amazon EFS) provides a serverless, fully elastic file system that automatically scales on demand to petabytes without disrupting applications. It eliminates the need to provision and manage capacity as you add and remove files, making it ideal for use with AWS Cloud services and on-premises resources.

In this lab, you will:

- Learn about persistent network storage
- Configure and deploy the EFS CSI Driver for Kubernetes
- Implement dynamic provisioning using EFS in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon EFS with Amazon EKS for scalable, persistent storage solutions.
