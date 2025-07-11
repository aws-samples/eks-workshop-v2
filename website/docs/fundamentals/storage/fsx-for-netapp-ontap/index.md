---
title: FSx for NetApp ONTAP
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Fully managed shared storage for workloads on Amazon Elastic Kubernetes Service with Amazon FSx for NetApp ONTAP."
---

::required-time{estimatedLabExecutionTimeMinutes="60"}

:::caution

Provisioning the FSx For NetApp ONTAP file system and associated infrastructure can take up to 30 minutes. Please take that in to account before starting this lab, and expect the `prepare-environment` command to take longer than other labs you may have done.

:::

:::tip Before you start
Prepare your environment for this section:

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/fsxn
```

:::

[Amazon FSx for NetApp ONTAP](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/what-is-fsx-ontap.html) (FSxN) is a storage service that allows you to launch and run fully managed ONTAP file systems in the cloud. ONTAP is NetApp's file system technology that provides a widely adopted set of data access and data management capabilities. Amazon FSx for NetApp ONTAP provides the features, performance, and APIs of on-premises NetApp file systems with the agility, scalability, and simplicity of a fully managed AWS service

In this lab, you will:

- Learn about persistent network storage
- Configure and deploy the FSx for NetApp ONTAP CSI Driver for Kubernetes
- Implement dynamic provisioning using FSx for NetApp ONTAP in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon FSx for NetApp ONTAP with Amazon EKS for fully managed, enterprise-grade, persistent storage solutions.
