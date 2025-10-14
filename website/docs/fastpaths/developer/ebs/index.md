---
title: Workload storage with Amazon EBS
sidebar_position: 40
description: "Persistent block storage for workloads on Amazon Elastic Kubernetes Service with Amazon Elastic Block Store."
---

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes the **Amazon EBS CSI Driver**, which enables dynamic provisioning of persistent block storage volumes.
:::

[Amazon Elastic Block Store](https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html) (Amazon EBS) provides persistent block storage volumes for use with Amazon EC2 and Amazon EKS. EBS volumes are highly available and reliable storage that can be attached to running instances in the same Availability Zone.

With Amazon EKS Auto Mode, the EBS CSI Driver comes pre-installed and managed by AWS, eliminating the need for manual installation and configuration.

In this lab, you will:

- Learn about persistent block storage with EBS
- Configure the catalog MySQL database to use persistent EBS volumes
- Verify data persistence across pod restarts

This hands-on experience will demonstrate how to effectively use Amazon EBS with EKS Auto Mode for persistent storage solutions.
