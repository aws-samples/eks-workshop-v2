---
title: "Cluster Over-Provisioning"
sidebar_position: 40
---

The Kubernetes [Cluster Autoscaler (CA) for AWS](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md) configures [AWS EC2 Auto Scaling group (ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html) of the [EKS Nodegroup](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) to scale nodes in cluster when there are pods pending to be scheduled.

This process of adding nodes to the cluster by modifying the ASG inherently adds extra time before pods could be scheduled. The time delay might not be desirable for scaling **critical applications**.

There are different approaches to solve this problem. This workshop solves this by **over provisioning** clusters with extra node(s) that run lower priority pods used as **placeholders**. These lower priority and are evicted when critical application pods are deployed. The empty pods not only make sure CPU and Memory resources are reserved but also IP addresses assigned from the [AWS VPC Container Network Interface - CNI](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html).

Before we begin let's reset our environment:

```bash timeout=300 wait=30
reset-environment
```