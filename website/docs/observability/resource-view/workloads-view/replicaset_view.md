---
title: "ReplicaSets"
sidebar_position: 40
---

A ReplicaSet is a kubernetes object that ensures a stable set of replica Pods are running at all times. As such, it is often used to guarantee the availability of a specified number of identical Pods. In the example below you can see 2 replicasets for namespace 'orders'. The replicaset for orders-d6b4566fc defines the configuration for desired and current number of pods.

![Insights](/img/resource-view/replica-set.jpg)

Click on the replicaset <i>orders-d6b4566fc</i> and explore the configuration. You will see configurations under Info, Pods , labels and details of max and desired replicas.

![Insights](/img/resource-view/rs-detail.jpg)

