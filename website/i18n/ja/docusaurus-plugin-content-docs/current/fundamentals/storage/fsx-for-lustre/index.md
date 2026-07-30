---
title: Amazon FSx for Lustre
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "High-performance parallel file storage for workloads on Amazon Elastic Kubernetes Service with Amazon FSx for Lustre."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=30
$ prepare-environment fundamentals/storage/fsxl
```

This will make the following changes to your lab environment:

- Create an IAM role for the FSx for Lustre CSI driver
- Create a security group with rules necessary to access the Amazon FSx for Lustre file system from the EKS cluster
- Create an Amazon FSx for Lustre file system

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxl/.workshop/terraform).

:::

[Amazon FSx for Lustre](https://docs.aws.amazon.com/fsx/latest/LustreGuide/what-is.html) provides a high-performance parallel file system optimized for fast processing of workloads such as machine learning, high performance computing (HPC), video processing, financial modeling, and electronic design automation (EDA). FSx for Lustre delivers sub-millisecond latencies, up to hundreds of gigabytes per second of throughput, and millions of IOPS.

FSx for Lustre supports multiple deployment types:

- **SCRATCH_1 and SCRATCH_2**: Temporary storage optimized for short-term processing of data. Data is not replicated and does not persist if a file server fails.
- **PERSISTENT_1 and PERSISTENT_2**: Longer-term storage where data is replicated within the same Availability Zone and supports automatic failover.

In this lab, you will:

- Learn about high-performance parallel file storage
- Configure and deploy the FSx for Lustre CSI Driver for Kubernetes
- Implement dynamic provisioning using FSx for Lustre in a Kubernetes deployment

This hands-on experience will demonstrate how to effectively use Amazon FSx for Lustre with Amazon EKS for high-performance, parallel persistent storage solutions.
