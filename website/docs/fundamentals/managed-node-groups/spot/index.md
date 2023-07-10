---
title: Spot instances
sidebar_position: 50
---

All of our existing compute nodes are using On-Demand capacity. However, there are multiple "[purchase options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html)" available to EC2 customers for running their EKS workloads.

A Spot Instance uses spare EC2 capacity that is available for less than the On-Demand price. Because Spot Instances enable you to request unused EC2 instances at steep discounts, you can lower your Amazon EC2 costs significantly. The hourly price for a Spot Instance is called a Spot price. The Spot price of each instance type in each Availability Zone is set by Amazon EC2, and is adjusted gradually based on the long-term supply of and demand for Spot Instances. Your Spot Instance runs whenever capacity is available.

Spot Instances are a good fit for stateless, fault-tolerant, flexible applications. These include batch and machine learning training workloads, big data ETLs such as Apache Spark, queue processing applications, and stateless API endpoints. Because Spot is spare Amazon EC2 capacity, which can change over time, we recommend that you use Spot capacity for interruption-tolerant workloads. More specifically, Spot capacity is suitable for workloads that can tolerate periods where the required capacity isn't available.

In this lab exercise, we'll look at how we can provision Spot capacity for our EKS cluster and deploy workloads that leverage it.

# EKS managed node groups with Spot capacity

Amazon EKS managed node groups with Spot capacity enhances the managed node group experience with ease to provision and manage EC2 Spot Instances. EKS managed node groups launch an EC2 Auto Scaling group with Spot best practices and handle Spot Instance interruptions automatically. This enables you to take advantage of the steep savings that Spot Instances provide for your interruption tolerant containerized applications. In addition, EKS managed node groups with Spot capacity have the following advantages:

* Allocation strategy to provision Spot capacity is set to Capacity Optimized to ensure that Spot nodes are provisioned in the optimal Spot capacity pools.
* Specify multiple instance types during managed node groups creation, to increase the number of Spot capacity pools available for allocating capacity.
* Nodes provisioned under managed node groups with Spot capacity are automatically tagged with capacity type: `eks.amazonaws.com/capacityType: SPOT`. You can use this label to schedule fault tolerant applications on Spot nodes.
* Amazon EC2 Spot Capacity Rebalancing enabled to ensure Amazon EKS can gracefully drain and rebalance your Spot nodes to minimize application disruption when a Spot node is at elevated risk of interruption.


Let’s get started by listing all of the nodegroups in our existing EKS Cluster, The `kubectl get nodes` command can be used to list the nodes in your Kubernetes cluster. To include additional labels such as `eks.amazonaws.com/capacityType` and `eks.amazonaws.com/nodegroup` in the output, you can use <b>“-L, —label-columns”</b> as additional attributes 

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup

NAME                                         STATUS   ROLES    AGE    VERSION                CAPACITYTYPE   NODEGROUP
ip-10-42-10-232.us-west-2.compute.internal   Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-system-20230605211737831800000026
ip-10-42-10-96.us-west-2.compute.internal    Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-ondemand-20230605211738568600000028
ip-10-42-12-45.us-west-2.compute.internal    Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-ondemand-20230605211738568600000028
```

:::tip
You can leverage <b>label selectors</b> if you want to pull nodes based on specific capacity type, In this case we have set `capacityType=ON_DEMAND`

```bash
$ kubectl get nodes -l eks.amazonaws.com/capacityType=ON_DEMAND

NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-119.us-east-2.compute.internal   Ready    <none>   3d10h   v1.23.15-eks-49d8fe8
ip-10-42-10-200.us-east-2.compute.internal   Ready    <none>   3d10h   v1.23.15-eks-49d8fe8
ip-10-42-11-94.us-east-2.compute.internal    Ready    <none>   3d10h   v1.23.15-eks-49d8fe8
ip-10-42-12-235.us-east-2.compute.internal   Ready    <none>   4h34m   v1.23.15-eks-49d8fe8

:::

In the below diagram, there are two separate Node Group representing the managed node groups within the cluster. The first Node Group box represents the node group containing On-Demand instances while the second represents the node group containing Spot instances, Both are associated with the specified EKS cluster.

![spot arch](../assets/managed-spot-arch.png)

As our existing cluster already has a nodegroup with `On-Demand` instances, The next step would be to setup a node group which has EC2 instances with capacity type as `SPOT`. 

To achieve that, We will do following:

* Export the Managed Node Group name for SPOT

* Use AWS CLI to create EKS managed node group for SPOT

```bash

$ export EKS_DEFAULT_MNG_NAME_SPOT=managed-spot
$ aws eks create-nodegroup \
--cluster-name $EKS_CLUSTER_NAME \
--nodegroup-name $EKS_DEFAULT_MNG_NAME_SPOT \
--node-role $MANAGED_NODE_GROUP_IAM_ROLE_ARN \
--subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
--instance-types m5.large m5d.large m5a.large m5ad.large m5n.large m5dn.large \
--capacity-type SPOT \
--scaling-config minSize=2,maxSize=6,desiredSize=2 \
--disk-size 20 \
--labels capacity_type=managed_spot

```
To track the status of Node Group creation, You can running below command in a separate terminal.

```bash
$ eksctl get nodegroup --cluster=$EKS_CLUSTER_NAME

CLUSTER         NODEGROUP                                               STATUS          CREATED                 MIN SIZE        MAX SIZE        DESIRED CAPACITY       INSTANCE TYPE                                                   IMAGE ID        ASG NAME                                                              TYPE
eks-workshop    managed-ondemand-20230605211832165500000026             ACTIVE          2023-06-05T21:18:33Z    2               6               2             m5.large                                                 AL2_x86_64      eks-managed-ondemand-20230605211832165500000026-b2c446b6-828d-f79f-9338-456374559c7b  managed
eks-workshop    managed-ondemand-tainted-20230605211832655900000028     ACTIVE          2023-06-05T21:18:34Z    0               1               0             m5.large                                                 AL2_x86_64      eks-managed-ondemand-tainted-20230605211832655900000028-84c446b6-837c-bf91-2e90-93ee1ec37cf8   managed
eks-workshop    managed-spot                                            CREATING        2023-06-06T05:24:55Z    2               6               2             m5.large,m5d.large,m5a.large,m5ad.large,m5n.large,m5dn.large     AL2_x86_64                                                                                    managed
eks-workshop    managed-system-20230605211832120700000024               ACTIVE          2023-06-05T21:18:34Z    1               2               1             m5.large                                                 AL2_x86_64      eks-managed-system-20230605211832120700000024-26c446b6-8271-ac8a-4b54-569cf51913f9    managed

```

:::info
The aws `eks wait nodegroup-active` command can be used to wait until a specific EKS node group is active and ready for use. This command is part of the AWS CLI and can be used to ensure that the specified node group has been successfully created and all the associated instances are running and ready.

```bash
$ aws eks wait nodegroup-active \
--cluster-name $EKS_CLUSTER_NAME \
--nodegroup-name $EKS_DEFAULT_MNG_NAME_SPOT
```
:::

Once the Managed node group `managed-spot` status shows as “<b>Active</b>”, Run the below command. 
The output shows that two additional nodes got provisioned under the node group `managed-spot` with capacity type as `SPOT`.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup

NAME                                         STATUS   ROLES    AGE    VERSION                CAPACITYTYPE   NODEGROUP
ip-10-42-10-232.us-west-2.compute.internal   Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-system-20230605211737831800000026
ip-10-42-10-96.us-west-2.compute.internal    Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-ondemand-20230605211738568600000028
ip-10-42-11-17.us-west-2.compute.internal    Ready    <none>   78s    v1.23.17-eks-0a21954   SPOT           managed-spot
ip-10-42-12-234.us-west-2.compute.internal   Ready    <none>   77s    v1.23.17-eks-0a21954   SPOT           managed-spot
ip-10-42-12-45.us-west-2.compute.internal    Ready    <none>   113m   v1.23.15-eks-49d8fe8   ON_DEMAND      managed-ondemand-20230605211738568600000028

```
From the above output you can see that now we have two managed nodegroups available. Next, let’s deploy the “Sample Retail Store” app and leverage [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) as node selection constraint to deploy app on top of the spot instances instead of On-Demand. Using the nodeSelector field, you can specify key-value pairs to filter and select which nodes in the cluster should run particular pods. It is used to define constraints for pod placement based on node labels. 

Now because our existing manifest `deployment.yaml` located under `/workspace/manifests/catalog`  does not have `nodeSelector` as an attribute, we will use [kustomize](https://www.eksworkshop.com/docs/introduction/kustomize/) to modify the existing resource configuration without directly modifying the original manifests. 

```kustomization
fundamentals/mng/spot/deployment.yaml
Deployment/catalog
```

Next, Deploy the app.

```bash
$ kubectl apply -k /workspace/modules/fundamentals/mng/spot

namespace/catalog created
serviceaccount/catalog created
configmap/catalog created
secret/catalog-db created
service/catalog created
service/catalog-mysql created
deployment.apps/catalog created
statefulset.apps/catalog-mysql created
```

To make sure your app got deployed successfully, We will use `kubectl rollout status` command that allows you to check the status of a deployment in Kubernetes. It provides information about the progress of the rollout and the current state of the associated resources.
```bash
$ kubectl rollout status deployment/catalog -n catalog --timeout=5m
```
Once the application get’s deployed successfully, The Final step would be to check whether the app got deployed on `SPOT` instances, To do that run below script on your terminal.

```bash
$ for pod in $(kubectl get pods -l app.kubernetes.io/name=catalog -n $CATALOG_RDS_DATABASE_NAME  | awk 'NR>1 {print $1}'); do if [ "$pod" != "NAME" ]; then node=$(kubectl get pod $pod -o json -n $CATALOG_RDS_DATABASE_NAME | jq -r '.spec.nodeName'); node_group=$(kubectl get node $node -o json | jq -r '.metadata.labels."eks.amazonaws.com/capacityType"'); echo "$pod | $node | $node_group"; fi; done

```

```
Output:

catalog-5c48f886c-txk8c | ip-10-42-11-113.us-west-2.compute.internal | managed_spot
catalog-mysql-0 | ip-10-42-12-155.us-west-2.compute.internal | managed_spot
```
