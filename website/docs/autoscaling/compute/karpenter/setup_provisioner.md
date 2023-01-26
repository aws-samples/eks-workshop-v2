---
title: "Set up the Provisioner"
sidebar_position: 30
---

Karpenter configuration comes in the form of a Provisioner CRD (Custom Resource Definition). A single Karpenter Provisioner is capable of handling many different Pod shapes. Karpenter makes scheduling and provisioning decisions based on Pod attributes such as labels and affinity. A cluster may have more than one Provisioner, but for the moment we'll declare just one: the default Provisioner. 

One of the main objectives of Karpenter is to simplify the management of capacity. If you're familiar with other auto scaling solutions, you may have noticed that Karpenter takes a different approach, referred to as **group-less auto scaling**. Other Solutions have traditionally used the concept of a **node group** as the element of control that defines the characteristics of the capacity provided (i.e: On-Demand, EC2 Spot, GPU Nodes, etc) and that controls the desired scale of the group in the cluster. In AWS the implementation of a node group matches with [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). Over time, clusters using this paradigm, that run different type of applications requiring different capacity types, end up with a complex configuration and operational model where node groups must be defined and provided in advance. 

This is the provisioner we'll created initially:

```file
autoscaling/compute/karpenter/provisioner/provisioner.yaml
```

:::info
We're asking the Provisioner to start all new nodes with a label `type: karpenter`, which will allow us to specifically target Karpenter nodes with Pods for demonstration purposes
:::

The configuration for the provider is split into two parts. The first one defines the general Provisioner specification. The second part is defined by the provider implementation, in our case `AWSNodeTemplate` and provides the specific configuration that applies to that cloud provider. This particular Provisioner configuration is quite simple, but during the workshop we'll change the Provisioner . For the moment let's focus in a few of the settings used.

* **Requirements Section**: The [Provisioner CRD](https://karpenter.sh/docs/provisioner-crd/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, and  `karpenter.k8s.aws/instance-type` to limit to specific instance types. You can learn which other properties are [available here](https://karpenter.sh/v0.13.1/tasks/scheduling/#selecting-nodes). We'll work on a few more during the workshop.
* **Limits section**: Provisioners can define a limit in the number of CPU's and memory that each Provisioner can manage. Once this limit is reached Karpenter will not provision additional capacity associated with that particular Provisioner, providing a cap on the total compute.
* **Tags**: Provisioners can also define a set of tags that the EC2 instances will have upon creation. This helps to enable accounting and governance at the EC2 level.
* **Selectors**: This `AWSNodeTemplate` resource uses `securityGroupSelector` and `subnetSelector` to discover resources used to launch nodes. These tags were automatically set on the associated AWS infrastructure provided for the workshop.

```bash timeout=180
$ kubectl apply -k /workspace/modules/autoscaling/compute/karpenter/provisioner
```

Throughout the workshop you can inspect the Karpenter logs with the following command to understand its behavior:

```bash
$ kubectl logs deployment/karpenter -c controller -n karpenter
```
