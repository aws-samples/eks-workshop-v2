---
title: Amazon EFS
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) is a simple, serverless, set-and-forget elastic file system for use with AWS Cloud services and on-premises resources. It's built to scale on demand to petabytes without disrupting applications, growing and shrinking automatically as you add and remove files, eliminating the need to provision and manage capacity to accommodate growth.

In this lab, we'll learn about the following concepts:
* Assets microservice deployment
* EFS CSI Driver
* Dynamic provisioning using EFS and Kuberneties deployment 
