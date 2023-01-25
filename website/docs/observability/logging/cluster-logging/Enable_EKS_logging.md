---
title: "Configuring control plane logs"
sidebar_position: 30
---

So that we have some data to look at in subsequent sections control plane logging was enabled when the cluster was created. Let's take a look at the configuration in the EKS console:

https://console.aws.amazon.com/eks/home#/clusters/eks-workshop?selectedTab=cluster-logging-tab

The **Logging** tab shows the current configuration for control plane logs for the cluster:

![EKS Console Logging Tab](./assets/logging-cluster-logging-tab.png)

You can alter the logging configuration by clicking the **Manage** button:

![Enable Logging](./assets/logging-cluster-enable-logging.png)
