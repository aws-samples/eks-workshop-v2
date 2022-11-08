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



There are two ways to provision and upgrade your worker nodes - <strong>Self-managed node groups</strong> and <strong>Managed node groups</strong>, This workshop uses a managed node group which is where our sample application is running by default Managed Node groups makes it easier for us to automate both the AWS and the Kubernetes side of the process.
<p> </p>
The Amazone EKS Managed worker node upgrade has 4 phases. 
<p> </p>
<h3>Setup  >  Scale Up  > Upgrade > Scale Down</h3> 
<p> </p>
<h4>Setup:</h4>

* Update Amazon EC2 Launch Template version associated with Auto Scaling group with the latest AMI
* Point your Auto Scaling group to use the latest version of the launch template
* Modify <code>updateconfig</code> with number of nodes where you want to run parallel upgrades

<h4>Scale Up:</h4>

* During the upgrade process, The upgraded nodes are launched in the same availability zone
* Increments the Auto Scaling Group’s maximum size and desired size by the larger of either:
* After scaling the Auto Scaling Group, it checks if the nodes using the latest configuration are present in the node group. 
* Applies an <code>eks.amazonaws.com/nodegroup=unschedulable:NoSchedule</code> taint on every node in the node group without the latest labels. This prevents nodes that have already been updated from a previous failed update from being tainted.

<h4>Upgrade:</h4>

* Randomly selects a node, Drains the pods from the node. If the pods don't leave the node within 15 minutes and there's no force flag, the upgrade phase fails with a <code>PodEvictionFailure</code> error. For this scenario, you can apply the force flag with the <code>update-nodegroup-version</code> request to delete the pods.
* Cordons the node after every pod is evicted and waits for 60 seconds, Sends a termination request to the Auto Scaling Group for the cordoned node.
* Applies same accross all nodes which are part of Managed Node group making sure there are no nodes with older version

<h4>Scale Down:</h4>

* The scale down phase decrements the Auto Scaling group maximum size and desired size by one to return to values before the update started.

To know more about Manged node group update behavior [Managed Node group Update phases](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html)


To trigger the manage node group upgrade process, Run the following eksctl command:

```bash
$ eksctl upgrade nodegroup --name=nodegroup --cluster=$EKS_CLUSTER_NAME --kubernetes-version=<Your_kubernetes_version>
```

In another Terminal tab you can follow the progress with:

```bash
$ kubectl get nodes --watch
```

