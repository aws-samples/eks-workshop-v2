---
title: Amazon EBS
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[Amazon Elastic Block Store](https://aws.amazon.com/ebs/) is an easy-to-use, scalable, high-performance block-storage service. It provides persistent volume (non-volatile storage) to users. Persistent storage enables users to store their data until they decide to delete the data.

In this lab, we'll learn about the following concepts:
* Kubernetes StatefulSets
* EBS CSI Driver
* StatefulSet with EBS Volume
