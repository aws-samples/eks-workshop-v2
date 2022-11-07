---
title: "Enable EKS cluster logging"
sidebar_position: 30
---

In this module, we will see how to enable the Amazon EKS control plane logs and verify it in Amazon CloudWatch logs.

1. To enable Amazon EKS control plane from the AWS console, login to EKS console, select the cluster, then select **Logging** tab to check the logging status, by default the logging will be disabled.

![EKS Console Logging Tab](/img/observability-logging/logging-cluster-logging-tab.png)

2. From the **Logging** Tab, choose **Manage Logging**, **Enable** the each log type and **Save** the changes to finish

![Enable Logging](/img/observability-logging/logging-cluster-enable-logging.png)