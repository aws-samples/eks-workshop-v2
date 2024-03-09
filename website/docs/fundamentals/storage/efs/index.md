---
title: Amazon EFS
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

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

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) is a simple, serverless, set-and-forget elastic file system for use with AWS Cloud services and on-premises resources. It's built to scale on demand to petabytes without disrupting applications, growing and shrinking automatically as you add and remove files, eliminating the need to provision and manage capacity to accommodate growth.

In this lab, we'll learn about the following concepts:
* Assets microservice deployment
* EFS CSI Driver
* Dynamic provisioning using EFS and a Kubernetes deployment 
