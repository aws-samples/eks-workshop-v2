---
title: Taints
sidebar_position: 40
---

Taints are a property of a node to repel certain pods. Tolerations are applied to pods to allow their scheduling onto nodes with matching taints. Taints and tolerations work together to ensure that pods are not scheduled on unsuitable nodes. While tolerations allow pods to be scheduled on nodes with matching taint, this isn't a guarantee and other Kuberenetes concepts like node affinity or node selectors will have to be used to achieve desired configuration. 

The configuration of tainted nodes is useful in scenarios where we need to ensure that only specific pods are to be scheduled on certain node groups with special hardware (such as attached GPUs) or when we want to dedicate entire node groups to a particular set of Kubernetes users. 

In this lab exercise, we'll learn how to configure taints for our managed node groups and how to set up our applications to make use of tainted nodes. 
