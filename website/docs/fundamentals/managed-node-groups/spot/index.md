---
title: Spot instances
sidebar_position: 50
---

All of our existing compute nodes are using On-Demand capacity. However, there are multiple "purchase options" available to EC2 customers, and that includes when using EKS.

A Spot Instance is an instance that uses spare EC2 capacity that is available for less than the On-Demand price. Because Spot Instances enable you to request unused EC2 instances at steep discounts, you can lower your Amazon EC2 costs significantly. The hourly price for a Spot Instance is called a Spot price. The Spot price of each instance type in each Availability Zone is set by Amazon EC2, and is adjusted gradually based on the long-term supply of and demand for Spot Instances. Your Spot Instance runs whenever capacity is available.

Spot Instances are a cost-effective choice if you can be flexible about when your applications run and if your applications can be interrupted. For example, Spot Instances are well-suited for data analysis, batch jobs, background processing, and optional tasks. For more information, see [Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot-instances/).

In this lab exercise, we'll look at how we can provision Spot capacity for our EKS cluster and deploy workloads that leverage it.

# EKS managed node groups with Spot capacity

Amazon EKS managed node groups with Spot capacity enhances the managed node group experience with ease to provision and manage EC2 Spot Instances. EKS managed node groups launch an EC2 Auto Scaling group with Spot best practices and handle [Spot Instance interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html) automatically. This enables you to take advantage of the steep savings that Spot Instances provide for your interruption tolerant containerized applications.

In addition to the advantages of managed node groups, EKS managed node groups with Spot capacity have these additional advantages:

* Allocation strategy to provision Spot capacity is set to [Capacity Optimized](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html#use-capacity-optimized-allocation-strategy) to ensure that Spot nodes are provisioned in the optimal Spot capacity pools.
* Specify [multiple instance types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html#be-instance-type-flexible) during managed node groups creation, to increase the number of Spot capacity pools available for allocating capacity.
* Nodes provisioned under managed node groups with Spot capacity are automatically tagged with capacity type: `eks.amazonaws.com/capacityType: SPOT`. You can use this label to schedule fault tolerant applications on Spot nodes.
* Amazon EC2 Spot [Capacity Rebalancing](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html) enabled to ensure Amazon EKS can gracefully drain and rebalance your Spot nodes to minimize application disruption when a Spot node is at elevated risk of interruption.
