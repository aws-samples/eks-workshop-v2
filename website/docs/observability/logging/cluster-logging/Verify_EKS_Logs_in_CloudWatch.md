---
title: "Viewing in CloudWatch"
sidebar_position: 30
---

Let's take a look at the logs in the CloudWatch Logs console:

https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups

Filter for **/aws/eks** prefix and select the cluster you want verify the logs:

![Cluster Loggroup](./assets/logging-cluster-cw-loggroup.png)

You will be presented with a number of log streams in the group:

![LogStream](./assets/logging-cluster-cw-logstream.png)

Select any of these log streams to view the entries being sent to CloudWatch Logs by the EKS control plane.
