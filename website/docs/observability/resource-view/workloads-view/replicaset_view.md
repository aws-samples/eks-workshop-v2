---
title: "ReplicaSets"
sidebar_position: 40
---

A [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) is a Kubernetes object that ensures a stable set of replica pods are running at all times. As such, it is often used to guarantee the availability of a specified number of identical pods. In this example (below), you can see 2 replicasets for namespace <i>orders</i>. The replicaset for orders-d6b4566fc defines the configuration for desired and current number of pods.

![Insights](/img/resource-view/replica-set.jpg)

Click on the replicaset <i>orders-d6b4566fc</i> and explore the configuration. You will see configurations under Info, Pods, labels and details of max and desired replicas.

![Insights](/img/resource-view/rs-detail.jpg)
