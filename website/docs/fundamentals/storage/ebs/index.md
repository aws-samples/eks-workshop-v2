---
title: Amazon EBS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "High performance block storage for workloads on Amazon Elastic Kubernetes Service with Amazon Elastic Block Store."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/ebs
```

This will make the following changes to your lab environment:

- Create the IAM role needed for the EBS CSI driver addon

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform).

:::

[Amazon Elastic Block Store](https://aws.amazon.com/ebs/) is an easy-to-use, scalable, high-performance block-storage service. It provides persistent volume (non-volatile storage) to users. Persistent storage enables users to store their data until they decide to delete the data.

In this lab, we'll learn about the following concepts:

- Kubernetes StatefulSets
- EBS CSI Driver
- StatefulSet with EBS Volume
