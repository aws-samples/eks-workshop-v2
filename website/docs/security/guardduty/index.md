---
title: "Amazon GuardDuty for EKS"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Detect potentially suspicious activity in Amazon Elastic Kubernetes Service clusters with Amazon GuardDuty."
---

::required-time{estimatedLabExecutionTimeMinutes="20"}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment
```

:::

Amazon GuardDuty offers threat detection enabling you to continuously monitor and protect your AWS accounts, workloads, and data stored in Amazon Simple Storage Service (Amazon S3). GuardDuty analyzes continuous metadata streams generated from your account and network activity found in AWS CloudTrail Events, Amazon Virtual Private Cloud (VPC) Flow Logs, and domain name system (DNS) Logs. GuardDuty also uses integrated threat intelligence such as known malicious IP addresses, anomaly detection, and machine learning (ML) to more accurately identify threats.

Amazon GuardDuty makes it easy for you to continuously monitor your AWS accounts, workloads, and data stored in Amazon S3. GuardDuty operates completely independently from your resources, so there is no risk of performance or availability impacts to your workloads. The service is fully managed with integrated threat intelligence, anomaly detection, and ML. Amazon GuardDuty delivers detailed and actionable alerts that are easy to integrate with existing event management and workflow systems. There are no upfront costs and you pay only for the events analyzed, with no additional software to deploy or threat intelligence feed subscriptions required.

GuardDuty has two categories of protection for EKS:

1. EKS Audit Log Monitoring helps you detect potentially suspicious activities in your EKS clusters using Kubernetes audit log activity
1. EKS Runtime Monitoring provides runtime threat detection coverage for Amazon Elastic Kubernetes Service (Amazon EKS) nodes and containers within your AWS environment

In this section we'll look at both types of protection with practical examples.
