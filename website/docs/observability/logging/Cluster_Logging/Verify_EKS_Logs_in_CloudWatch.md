---
title: "Verify the EKS logs"
sidebar_position: 30
---

After you have enabled any of the control plane log types for your Amazon EKS cluster, you can view them on the CloudWatch console. Once enabled the cluster logs streamed to **/aws/eks/<clustername\>/cluster** CloudWatch log group.

1. To view your cluster control plane logs on the CloudWatch console, login to CloudWatch console, select **Log groups** from the left navigation pane, filter for **/aws/eks** prefix and select the cluster you want verify the logs.

![Cluster Loggroup](/img/observability-logging/logging-cluster-cw-loggroup.png)

2. Choose the log stream to view.

![LogStream](/img/observability-logging/logging-cluster-cw-logstream.png)
