---
title: Amazon S3 Files
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "Shared file system storage backed by Amazon S3 for workloads on Amazon Elastic Kubernetes Service with Amazon S3 Files."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/s3-files
```

This will make the following changes to your lab environment:

- Create an IAM role for the Amazon EFS CSI driver controller (used by S3 Files) with the `AmazonS3FilesCSIDriverPolicy` and `AmazonS3FilesClientFullAccess` policies
- Attach the S3 Files client, S3 read, and EFS utils policies to the worker node instance role so the CSI node daemonset can mount S3 file systems
- Create an Amazon S3 bucket with versioning enabled
- Create an Amazon S3 file system linked to the bucket
- Create mount targets for the S3 file system

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/s3-files/.workshop/terraform).

:::

[Amazon S3 Files](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files.html) is a shared file system that connects any AWS compute resource directly with your data in Amazon S3. It provides fast, direct access to all of your S3 data as files with full file system semantics and low-latency performance, without your data ever leaving S3. Built using Amazon EFS technology, S3 Files gives you the performance and simplicity of a file system with the scalability, durability, and cost-effectiveness of S3.

Unlike Mountpoint for Amazon S3 (which translates file operations into S3 API calls), S3 Files provides a true NFS-based file system with features like read-after-write consistency, file locking, and POSIX permissions. It intelligently routes reads between a high-performance storage layer and your S3 bucket for optimal performance.

In this lab, you will:

- Learn about S3 Files and how it provides file system access to S3 data
- Configure and deploy the EFS CSI Driver to mount an S3 file system on EKS
- Implement static provisioning using S3 Files in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon S3 Files with Amazon EKS for scalable, persistent storage solutions.

:::note
This lab uses **static provisioning** because the EFS CSI driver's dynamic provisioning path targets the Amazon EFS API, which cannot provision volumes against an S3 Files file system. If you need dynamic, on-demand provisioning of Amazon S3 object storage as a file system, see the [Mountpoint for Amazon S3](../mountpoint-s3/index.md) module. The [S3 Files CSI Driver](./s3-files-csi-driver.md) page explains this trade-off in more detail.
:::
