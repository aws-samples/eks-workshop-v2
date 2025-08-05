---
title: Amazon FSx for Lustre
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "Amazon FSx for Lustre is a fully managed service that provides high-performance, cost-effective, and scalable storage powered by Lustre, the world’s most popular high-performance file system"
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/fsxl
```

This will make the following changes to your lab environment:

- Create an IAM role for the Amazon FSx for Lustre CSI driver
- Create an Amazon Simple Storage Service (S3) bucket for use in the workshop

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxl/.workshop/terraform).

:::

[Amazon FSx for Lustre](https://aws.amazon.com/fsx/lustre/) is a fully managed service that provides high-performance, cost-effective, and scalable storage powered by Lustre, the world’s most popular high-performance file system. FSx for Lustre provides the fastest storage performance for GPU instances in the cloud with up to terabytes per second of throughput, millions of IOPS, sub-millisecond latencies, and virtually unlimited storage capacity. It delivers up to 34% better price performance compared to on-premises HDD file storage and up to 70% better price performance compared to other cloud-based Lustre storage.

The [Amazon FSx for Lustre Container Storage Interface (CSI) driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver) provides a CSI interface that allows Amazon EKS clusters to manage the lifecycle of Amazon FSx for Lustre file systems. 

In this lab, we will create an Amazon FSx for Lustre file system to provide persistent, shared storage for our EKS cluster. The FSx for Lustre file system uses an [S3](https://aws.amazon.com/s3/) bucket as the data repository, and a [Data Repository Association (DRA)](https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html) will be created between the the Lustre file system and the S3 bucket.

We will cover the following topics:

- Ephemeral Container Storage
- Introduction to FSx for Lustre
- FSx for Lustre with S3 DRA