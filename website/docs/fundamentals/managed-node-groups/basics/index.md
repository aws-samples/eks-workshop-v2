---
title: MNG basics
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Learn the fundamentals of Managed Node Groups on Amazon Elastic Kubernetes Service."
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=30
$ prepare-environment fundamentals/mng/basics
```

:::

In the Getting started lab, we deployed our sample application to EKS and saw the running Pods. But where are these Pods running?

We can inspect the default managed node group that was pre-provisioned for you:

```bash
$ eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_DEFAULT_MNG_NAME
```

There are several attributes of managed node groups that we can see from this output:

- Configuration of minimum, maximum and desired counts of the number of nodes in this group
- The instance type for this node group is `m5.large`
- Uses the `AL2_x86_64` EKS AMI type

We can also inspect the nodes and the placement in the availability zones.

```bash
$ kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

You should see:

- Nodes are distributed over multiple subnets in various availability zones, providing high availability

Over the course of this module we'll make changes to this node group to demonstrate the basic capabilities of MNGs.
