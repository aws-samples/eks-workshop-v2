---
title: "DaemonSet"
sidebar_position: 55
---

A [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) ensures that all (or some) Nodes run a copy of a pod. In the sample application we have DaemonSet running on each node as shown (below).

![Insights](/img/resource-view/daemonset.jpg)

Click on the daemonset <i>kube-proxy</i> and explore the configuration. You will see configurations under Info, pods running on each node, labels, and annotations.

![Insights](/img/resource-view/daemonset-detail.jpg)
