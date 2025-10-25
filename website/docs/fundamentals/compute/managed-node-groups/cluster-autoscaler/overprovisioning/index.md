---
title: "Cluster Over-Provisioning"
sidebar_position: 50
---

The Kubernetes [Cluster Autoscaler (CA) for AWS](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md) configures the [AWS EC2 Auto Scaling group (ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html) of the [EKS node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) to scale nodes in the cluster when there are pods pending scheduling.

This process of adding nodes to a cluster by modifying the ASG inherently adds extra time before pods can be scheduled. For example, in the previous section, you may have noticed it took several minutes before the pods created during application scaling became available.

There are numerous approaches to solve this problem. This lab exercise addresses the issue by "over-provisioning" the cluster with extra node(s) that run lower priority pods used as placeholders. These lower priority pods are evicted when critical application pods are deployed. The placeholder pods not only ensure CPU and Memory resources are reserved but also secure IP addresses assigned from the [AWS VPC Container Network Interface - CNI](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html).
