---
title: Add Spot Managed Node Group
sidebar_position: 10
---

We have our EKS cluster and nodes already, but we need some Spot Instances configured to run the workload. 
We will be creating a Spot managed node group to utilize Spot Instances. 
Managed node groups automatically create a label, **eks.amazonaws.com/capacityType** to identify which nodes are Spot Instances and which are On-Demand Instances so that we can schedule the appropriate workloads to run on Spot Instances.

First, we can check that the current nodes are running On-Demand by checking the **eks.amazonaws.com/capacityType** label is set to **ON_DEMAND**. The output of the command shows the **CAPACITYTYPE** for the current nodes is set to **ON_DEMAND**.

```bash
$ kubectl get nodes \
  --label-columns=eks.amazonaws.com/capacityType \
  --selector=eks.amazonaws.com/capacityType=ON_DEMAND
  
NAME                                              STATUS   ROLES    AGE    VERSION               CAPACITYTYPE
ip-10-42-10-73.ap-southeast-1.compute.internal    Ready    <none>   120m   v1.23.9-eks-ba74326   ON_DEMAND
ip-10-42-11-202.ap-southeast-1.compute.internal   Ready    <none>   105m   v1.23.9-eks-ba74326   ON_DEMAND
ip-10-42-12-103.ap-southeast-1.compute.internal   Ready    <none>   105m   v1.23.9-eks-ba74326   ON_DEMAND
ip-10-42-12-254.ap-southeast-1.compute.internal   Ready    <none>   120m   v1.23.9-eks-ba74326   ON_DEMAND


```

## Create Spot managed node group

We will now create the a Spot managed node group.

```bash test=false
$ aws eks create-nodegroup \
  --cluster-name=${EKS_CLUSTER_NAME} \
  --subnets ${PRIMARY_PUBLIC_SUBNET_1} ${PRIMARY_PUBLIC_SUBNET_2} \
  --nodegroup-name ng-spot \
  --node-role ${EKS_DEFAULT_MNG_ROLE_ARN} \
  --region=${AWS_DEFAULT_REGION} \
  --capacity-type SPOT \
  --instance-types m5.large m4.large m5d.large m5a.large m5ad.large m5n.large m5dn.large
```

:::caution
Note, the instances above might not be present in your region. To select instances that meet that criteria in your region, you could install [https://github.com/aws/amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector) and execute the command `ec2-instance-selector --base-instance-type m5.large --flexible` to get a diversified selection of instances available in your region of choice that meet the criteria of being similar to m4.large (in vCPU and memory terms)
:::

Spot managed node group creates a label **eks.amazonaws.com/capacityType** and sets it to **SPOT** for the nodes.

The Spot managed node group created follows Spot best practices including using [capacity-optimized](https://aws.amazon.com/blogs/compute/introducing-the-capacity-optimized-allocation-strategy-for-amazon-ec2-spot-instances/) as the spotAllocationStrategy, which will launch instances from the Spot Instance pools with the most available capacity (when EC2 needs the capacity back), aiming to decrease the number of Spot interruptions in our cluster.

```bash 
$ aws eks wait nodegroup-active \
    --cluster-name ${EKS_CLUSTER_NAME}  \
    --nodegroup-name ng-spot; echo "Nodegroup created"
 
Nodegroup created
```

:::info
The creation of the nodes will take about 3 minutes.
:::

## Confirm the Nodes

Confirm that the new nodes joined the cluster correctly. You should see 2 more nodes added to the cluster.

```bash
$ kubectl get nodes --sort-by=.metadata.creationTimestamp
 
NAME                                              STATUS   ROLES    AGE    VERSION
ip-10-42-12-254.ap-southeast-1.compute.internal   Ready    <none>   125m   v1.23.9-eks-ba74326
ip-10-42-10-73.ap-southeast-1.compute.internal    Ready    <none>   125m   v1.23.9-eks-ba74326
ip-10-42-11-202.ap-southeast-1.compute.internal   Ready    <none>   110m   v1.23.9-eks-ba74326
ip-10-42-12-103.ap-southeast-1.compute.internal   Ready    <none>   110m   v1.23.9-eks-ba74326
ip-10-42-0-45.ap-southeast-1.compute.internal     Ready    <none>   2m6s   v1.23.13-eks-fb459a0
ip-10-42-1-233.ap-southeast-1.compute.internal    Ready    <none>   2m5s   v1.23.13-eks-fb459a0


```

You can use the **eks.amazonaws.com/capacityType** to identify the lifecycle of the nodes. The output of this command should return 2 nodes with the **CAPACITYTYPE** set to **SPOT**.

```bash
$ kubectl get nodes \
  --label-columns=eks.amazonaws.com/capacityType \
  --selector=eks.amazonaws.com/capacityType=SPOT
 
NAME                                             STATUS   ROLES    AGE     VERSION                CAPACITYTYPE
ip-10-42-0-45.ap-southeast-1.compute.internal    Ready    <none>   2m28s   v1.23.13-eks-fb459a0   SPOT
ip-10-42-1-233.ap-southeast-1.compute.internal   Ready    <none>   2m27s   v1.23.13-eks-fb459a0   SPOT

```

