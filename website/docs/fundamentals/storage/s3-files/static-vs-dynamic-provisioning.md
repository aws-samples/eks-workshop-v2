---
title: Static vs. dynamic provisioning
sidebar_position: 25
---

Before we provision storage for our S3 file system, it's important to understand the two ways the EFS CSI driver can attach storage to your Pods, and why this lab uses one over the other.

The EFS CSI driver can attach storage to your Pods using two different approaches:

- **Dynamic provisioning**: You define a `StorageClass`, and when a Pod's `PersistentVolumeClaim` requests storage, the driver automatically creates a matching `PersistentVolume` on demand. For the EFS CSI driver, this means the driver creates a new EFS *access point* for each claim, backed by an existing Amazon EFS file system referenced in the `StorageClass` parameters.
- **Static provisioning**: You (or your infrastructure automation) create the storage backend and a `PersistentVolume` that points directly at it *ahead of time*. The `PersistentVolumeClaim` then binds to that pre-existing volume instead of triggering on-demand creation.

:::info Why this lab uses static provisioning
The EFS CSI driver's dynamic provisioning path calls the **Amazon EFS** `CreateAccessPoint` API against the file system ID in the `StorageClass`. Amazon S3 Files file systems live in the separate **S3 Files** service and are not created or resolved through that EFS dynamic-provisioning API, so dynamic provisioning cannot create volumes against an S3 Files file system.

For S3 Files, the file system is created in advance (our automation did this for you) and mounted through a **statically provisioned** `PersistentVolume`. This is the provisioning model AWS documents for [mounting S3 file systems on Amazon EKS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files-mounting-eks.html).
:::

:::tip Looking for dynamic provisioning of S3 object storage?
If your use case needs dynamic, on-demand provisioning of Amazon S3 object storage as a file system, use the [Mountpoint for Amazon S3](../mountpoint-s3/index.md) module instead. Mountpoint for Amazon S3 exposes an S3 bucket as a file system and supports both static and dynamic provisioning through its own CSI driver. The trade-off is that Mountpoint provides S3 object semantics (it translates file operations into S3 API calls) rather than the full NFS file system semantics — such as read-after-write consistency and file locking — that S3 Files provides.
:::

Now that we understand why we use static provisioning for S3 Files, we're ready to statically provision a `PersistentVolume` for our S3 file system and modify the UI component to use it for storing product images.
