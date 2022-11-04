---
title: Upgrade Managed Node Group
sidebar_position: 60
---

Amazon EKS gives the end users the flexibility to deploy nodes either with Amazon Linux AMI's or build your own custom AMI's, When you initiate a managed node group update. Amazon EKS automatically update your nodes by applying the latest security patches and OS updates. 
With Amazon EKS managed node groups, you don’t need to separately provision or register the Amazon EC2 instances that provide compute capacity to run your Kubernetes applications. You can create, automatically update, or terminate nodes for your cluster with a single operation. Node updates and terminations automatically drain nodes to ensure that your applications stay available.

<p> You can add a managed node group to new or existing clusters using the Amazon EKS console, eksctl, AWS CLI; AWS API, or infrastructure as code tools including AWS CloudFormation. Nodes launched as part of a managed node group are automatically tagged for auto-discovery by the Kubernetes cluster autoscaler. You can use the node group to apply Kubernetes labels to nodes and update them at any time.</p>

Below are the list of the supported Node OS:

* [Amazon Linux Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
* [Ubuntu Linux](https://docs.aws.amazon.com/eks/latest/userguide/eks-partner-amis.html) 
* [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html)
* [Windows](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-windows-ami.html)


For more details on the latest AMI release versions and their changelog: [Amazon Linux AMI](https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md) || [Bottlerocket AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html) || [Windows AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html)


<strong> Pricing: </strong> There are no additional costs to use Amazon EKS managed node groups, you only pay for the AWS resources you provision. These include Amazon EC2 instances, Amazon EBS volumes, Amazon EKS cluster hours, and any other AWS infrastructure. There are no minimum fees and no upfront commitments.
<p> </p>
<blockquote><strong>Note:</strong> Starting with kubernetes version 1.24, Amazon EKS will end the support for <code>Dockershim</code>. The only runtime available would be
<code>containerd</code>.</blockquote>

<p> </p>

There are two ways to provision and upgrade your worker nodes - Self-managed node groups and Managed node groups, This workshop uses a managed node group which is where our sample application is running by default Managed Node groups makes it easier for us to automate both the AWS and the Kubernetes side of the process.

<p> </p>

1. Amazon EKS creates a new Amazon EC2 launch template version for the Auto Scaling group associated with your node group. The new template uses the target AMI for the update.
2. The Auto Scaling group is updated to use the latest launch template with the new AMI.
3. The Auto Scaling group maximum size and desired size are incremented by one up to twice the number of Availability Zones in the Region that the Auto Scaling group is deployed in. This is to ensure that at least one new instance comes up in every Availability Zone in the Region that your node group is deployed in.
Amazon EKS checks the nodes in the node group for the eks.amazonaws.com/nodegroup-image label, and applies a `eks.amazonaws.com/nodegroup=unschedulable:NoSchedule` taint on all of the nodes in the node group that aren’t labeled with the latest AMI ID. This prevents nodes that have already been updated from a previous failed update from being tainted.
4. Amazon EKS randomly selects a node in the node group and evicts all pods from it.
5. After all of the pods are evicted, Amazon EKS cordons the node. This is done so that the service controller doesn’t send any new request to this node and removes this node from its list of healthy, active nodes.
6. Amazon EKS sends a termination request to the Auto Scaling group for the cordoned node.
7. Steps 5-7 are repeated until there are no nodes in the node group that are deployed with the earlier version of the launch template.
The Auto Scaling group maximum size and desired size are decremented by 1 to return to your pre-update values.

To trigger the manage node group upgrade process, Run the following eksctl command:

```bash
$ eksctl upgrade nodegroup --name=nodegroup --cluster=$EKS_CLUSTER_NAME --kubernetes-version=<kubernetes_version>
```

In another Terminal tab you can follow the progress with:

```bash
$ kubectl get nodes --watch
```

