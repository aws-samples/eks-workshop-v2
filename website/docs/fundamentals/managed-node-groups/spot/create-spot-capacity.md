---
title: "Create spot capacity"
sidebar_position: 20
---

Lets deploy a managed node group that creates Spot instances, followed by modifying the existing `catalog` component of our application to run on the newly created Spot instances.

We can get started by listing all of the nodes in our existing EKS cluster. The `kubectl get nodes` command can be used to list the nodes in your Kubernetes cluster, but to get additional detail about the capacity type, we'll use the `-L eks.amazonaws.com/capacityType` parameter.

The following command shows that our nodes are currently **on-demand** instances.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType
NAME                                          STATUS   ROLES    AGE    VERSION                CAPACITYTYPE
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
```

:::tip
If you want to retrieve nodes based on a specific capacity type, such as `on-demand` instances, you can utilize "<b>label selectors</b>". In this particular scenario, you can achieve this by setting the label selector to `capacityType=ON_DEMAND`.

```bash
$ kubectl get nodes -l eks.amazonaws.com/capacityType=ON_DEMAND

NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-119.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-200.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-94.us-east-2.compute.internal    Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-235.us-east-2.compute.internal   Ready    <none>   4h34m   vVAR::KUBERNETES_NODE_VERSION
```

:::

In the below diagram, there are two separate "node groups" representing the managed node groups within the cluster. The first Node Group box represents the node group containing On-Demand instances while the second represents the node group containing Spot instances. Both are associated with the specified EKS cluster.

![spot arch](./assets/managed-spot-arch.webp)

Let's create a node group with Spot instances. The following command creates a new node group `managed-spot`.

```bash wait=10
$ aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot \
  --node-role $SPOT_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types c5.large c5d.large c5a.large c5ad.large c6a.large \
  --capacity-type SPOT \
  --scaling-config minSize=2,maxSize=3,desiredSize=2 \
  --disk-size 20
```

The `--capacity-type SPOT` argument indicates that all capacity in this managed node group should be Spot.

:::tip
The aws `eks wait nodegroup-active` command can be used to wait until a specific EKS node group is active and ready for use. This command is part of the AWS CLI and can be used to ensure that the specified node group has been successfully created and all the associated instances are running and ready.

```bash wait=30 timeout=300
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot
```

:::

Once our new managed node group is **Active**, run the following command.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup

NAME                                          STATUS   ROLES    AGE     VERSION                CAPACITYTYPE   NODEGROUP
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-178-46.us-east-2.compute.internal    Ready    <none>   103s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
ip-10-42-97-19.us-east-2.compute.internal     Ready    <none>   104s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
```

The output shows that two additional nodes got provisioned under the node group `managed-spot` with capacity type as `SPOT`.
