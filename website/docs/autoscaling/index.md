---
title: "Autoscaling"
sidebar_position: 5
weight: 30
---

Autoscaling monitors your workloads and automatically adjusts capacity to maintain steady, predictable performance while also optimizing for cost. When using Kubernetes there are two main relevant mechanisms which can be used to scale automatically:

* **Compute:** As pods are scaled the underlying compute in a Kubernetes cluster must also adapt by adjusting the number or size of worker nodes used to run the Pods.
* **Pods:** Since pods are used to run workloads in a Kubernetes cluster, scaling a workload is primarily done by scaling Pods either horizontally or vertically in response to scenarios such as changes in load on a given application.

In this chapter, we'll explore the various mechanisms available for automatically scaling both the number of pods and a cluster's compute capacity.
