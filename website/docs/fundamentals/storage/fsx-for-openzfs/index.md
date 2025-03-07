---
title: Amazon FSx for OpenZFS
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Fully managed, high-performance, elastic file storage for workloads on Amazon Elastic Kubernetes Service with Amazon FSx for OpenZFS."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/fsxz
```

This will make the following changes to your lab environment:

- Create an IAM OIDC provider
- Create a new security group with rules necessary to access the Amazon FSx for OpenZFS file system from the EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxz/.workshop/terraform).

:::

[Amazon FSx for OpenZFS](https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/what-is-fsx.html) (Amazon FSx for OpenZFS) provides a fully managed, high-performance shared file system accessible via both NFSv3 and NFSv4.  You have access to your shared data sets at microsoecond latencies with millions of IOPS and up to 21 GB/s of throughput.  FSx for OpenZFS also includes many enterprise features such as zero space snapshots, zero space clones, data replication, thin provisioning, user quotas, and compression.

There are two different storage classes; an all SSD-based storage class and an Intelligent-Tiering storage class.  File systems leveraging the SSD storage class provide consistent microsecond latencies.  Intelligent-Tiering file systems provide microsecond latencies for writes and cached reads and tens of milliseconds latency for read cache misses.  The Intelligent-Tiering storage class provides fully elastic storage capacity growing and shrinking with your dataset only charging for the capacity consumed all at S3 like pricing.

In this lab, you will:

- Learn about persistent network storage with the assets microservice
- Configure and deploy the FSx for OpenZFS CSI Driver for Kubernetes
- Implement dynamic provisioning using FSx for OpenZFS in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon FSx for OpenZFS with Amazon EKS for fully managed, high-performance, enterprise featured, elastic, persistent storage solutions.
