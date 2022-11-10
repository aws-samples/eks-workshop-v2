---
title: "Compute"
sidebar_position: 10
---

In Kubernetes the first aspect we want to ensure we are autoscaling is the EC2 compute infrastructure used to run our pods. This will adjust the number of EC2 instances available to the EKS cluster as worker nodes dynamically as pods are added or removed.

There are a number of ways to implement compute autoscaling in Kubernetes, and at AWS the two primary mechanisms available are:

* Kubernetes Cluster Autoscaler tool
* Karpenter

The following sections explore these tools.