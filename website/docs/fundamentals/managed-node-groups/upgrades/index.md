---
title: Upgrading AMIs
sidebar_position: 60
---

The [Amazon EKS optimized Amazon Linux AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-amis.html) is built on top of Amazon Linux 2, and is configured to serve as the base image for Amazon EKS nodes. It's considered a best practice to use the latest version of the EKS-Optimized AMI when you add nodes to an EKS cluster, as new releases include Kubernetes patches and security updates. It's also important to upgrade existing nodes already provisioned in the EKS cluster.

EKS managed node groups provides the capability to automate the update of the AMI being used by the nodes it manages. It will automatically drain nodes using the Kubernetes API and respects the [Pod disruption budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) that you set for your Pods to ensure that your applications stay available.

The Amazon EKS managed worker node upgrade has 4 phases:

**Setup**:

* Create a new Amazon EC2 Launch Template version associated with Auto Scaling group with the latest AMI
* Point your Auto Scaling group to use the latest version of the launch template
* Determine the maximum number of nodes to upgrade in parallel using the `updateconfig` property for the node group.

**Scale Up**:

* During the upgrade process, the upgraded nodes are launched in the same availability zone as those that are being upgraded
* Increments the Auto Scaling Group’s maximum size and desired size to support the additional nodes
* After scaling the Auto Scaling Group, it checks if the nodes using the latest configuration are present in the node group. 
* Applies a `eks.amazonaws.com/nodegroup=unschedulable:NoSchedule` taint on every node in the node group without the latest labels. This prevents nodes that have already been updated from a previous failed update from being tainted.

**Upgrade**:

* Randomly selects a node and drains the Pods from the node.
* Cordons the node after every Pod is evicted and waits for 60 seconds
* Sends a termination request to the Auto Scaling Group for the cordoned node.
* Applies same accross all nodes which are part of Managed Node group making sure there are no nodes with older version

**Scale Down**:

* The scale down phase decrements the Auto Scaling group maximum size and desired size by one until the the values are the same as before the update started.

To learn more about managed node group update behavior, see [managed node group update phases](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html).


### Upgrading a Managed Node Group

:::caution

Upgrading the node group will take at least 10 minutes, only execute this section if you have sufficient time

:::

The EKS cluster that has been provisioned for you intentionally has managed node groups that are not running the latest AMI. You can see what the latest AMI version is by querying SSM:

```bash
$ aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.23/amazon-linux-2/recommended/image_id --region $AWS_DEFAULT_REGION --query "Parameter.Value" --output text
ami-0fcd72f3118e0dd88
```

When you initiate a managed node group update, Amazon EKS automatically updates your nodes for you, completing the steps listed above. If you're using an Amazon EKS optimized AMI, Amazon EKS automatically applies the latest security patches and operating system updates to your nodes as part of the latest AMI release version. 

You can initiate an update of the managed node group used to host our sample application like so:

```bash
$ aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

You can watch activity on the nodes using `kubectl`:

```bash test=false
$ kubectl get nodes --watch
```

If you want to wait until the MNG is updated you can run the following command:

```bash timeout=1200
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

Once this is completed, you can proceed to the next step.
