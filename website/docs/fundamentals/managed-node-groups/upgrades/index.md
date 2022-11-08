---
title: Upgrade Managed Node Group
sidebar_position: 60
---

When you initiate a managed node group update, Amazon EKS automatically updates your nodes by applying the latest security patches and OS updates. You have the flexibility to deploy nodes either with Amazon Linux AMIs, Bottlerocket AMIs, Windows AMIs, or build-your-own custom AMIs.

With Amazon EKS managed node groups, you don’t need to separately provision or register the Amazon EC2 instances that provide compute capacity to run your Kubernetes applications. You can create, automatically update, or terminate nodes for your cluster with a single operation. Node updates and terminations automatically drain nodes to ensure that your applications stay available.

You can add a managed node group to new or existing clusters using the Amazon EKS console, `eksctl`, AWS CLI, AWS API, or infrastructure-as-code tools including AWS CloudFormation. Every managed node is provisioned as part of an Amazon EC2 Auto Scaling group managed for you by Amazon EKS. Nodes launched as part of a managed node group are automatically tagged for auto-discovery by the Kubernetes cluster autoscaler.

Below are the list of the supported Node OS:

* [Amazon Linux Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
* [Ubuntu Linux](https://docs.aws.amazon.com/eks/latest/userguide/eks-partner-amis.html) 
* [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html)
* [Windows](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-windows-ami.html)


For more details on the latest AMI release versions and their changelog: 
* [Amazon Linux AMI](https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md)
* [Bottlerocket AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html)
* [Windows AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html)


**Pricing:** There are no additional costs to use Amazon EKS managed node groups, you only pay for the AWS resources you provision. These include Amazon EC2 instances, Amazon EBS volumes, Amazon EKS cluster hours, and any other AWS infrastructure. There are no minimum fees and no upfront commitments.

> **Note:** Starting with kubernetes version 1.24, Amazon EKS will end the support for `Dockershim`. To learn more, refer to the following article in the [AWS documentation](https://docs.aws.amazon.com/eks/latest/userguide/dockershim-deprecation.html).

There are two ways to provision and upgrade your worker nodes - **Self-managed node groups** and **Managed node groups**. This workshop uses a managed node group which is where our sample application is running by default. Managed Node groups make it easier for us to automate both the AWS and the Kubernetes side of the process.

The Amazon EKS Managed worker node upgrade has 4 phases:
**Setup  >  Scale Up  > Upgrade > Scale Down**

### Setup:

* Create a new Amazon EC2 Launch Template version associated with Auto Scaling group with the latest AMI
* Point your Auto Scaling group to use the latest version of the launch template
* Determine the maximum number of nodes to upgrade in parallel using the `updateconfig` property for the node group.

### Scale Up:

* During the upgrade process, the upgraded nodes are launched in the same availability zone as those that are being upgraded
* Increments the Auto Scaling Group’s maximum size and desired size to support the additional nodes
* After scaling the Auto Scaling Group, it checks if the nodes using the latest configuration are present in the node group. 
* Applies a `eks.amazonaws.com/nodegroup=unschedulable:NoSchedule` taint on every node in the node group without the latest labels. This prevents nodes that have already been updated from a previous failed update from being tainted.

### Upgrade:

* Randomly selects a node and drains the pods from the node.
* Cordons the node after every pod is evicted and waits for 60 seconds
* Sends a termination request to the Auto Scaling Group for the cordoned node.
* Applies same accross all nodes which are part of Managed Node group making sure there are no nodes with older version

### Scale Down:

* The scale down phase decrements the Auto Scaling group maximum size and desired size by one until the the values are the same as before the update started.

To know more about Manged node group update behavior, see [Managed Node group Update phases](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html).


### Upgrade Managed Node Group (optional):

For reference, the following command can be run to trigger an upgrade of your node-group. If you're in a live workshop setting, note that this process takes time and may impact your ability to proceed to the next module.

```
$ eksctl upgrade nodegroup --name=nodegroup --cluster=$EKS_CLUSTER_NAME --kubernetes-version=<desired_kubernetes_version>
```

In another Terminal tab you can follow the progress with:

```
$ kubectl get nodes --watch
```

