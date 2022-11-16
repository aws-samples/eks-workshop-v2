---
title: Upgrading Managed Node Groups
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

The Amazon EKS Managed worker node upgrade has 4 phases:

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

* Randomly selects a node and drains the pods from the node.
* Cordons the node after every pod is evicted and waits for 60 seconds
* Sends a termination request to the Auto Scaling Group for the cordoned node.
* Applies same accross all nodes which are part of Managed Node group making sure there are no nodes with older version

**Scale Down**:

* The scale down phase decrements the Auto Scaling group maximum size and desired size by one until the the values are the same as before the update started.

To know more about Manged node group update behavior, see [Managed Node group Update phases](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html).


### Upgrading a Managed Node Group

:::caution

Upgrading the node group will take at least 10 minutes, only execute this section if you have sufficient time

:::

The EKS cluster that has been provisioned for you intentionally has Managed Node Groups that are not running the latest AMI. You can see what the latest AMI version is by querying SSM:

```bash
$ aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.23/amazon-linux-2/recommended/image_id --region $AWS_DEFAULT_REGION --query "Parameter.Value" --output text
ami-0fcd72f3118e0dd88
```

When you initiate a managed node group update, Amazon EKS automatically updates your nodes for you, completing the steps listed above. If you're using an Amazon EKS optimized AMI, Amazon EKS automatically applies the latest security patches and operating system updates to your nodes as part of the latest AMI release version. 

You can initiate an update of the Managed Node Group used to host our sample application like so:

```bash
$ aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

You can watch activity on the nodes using `kubectl`:

```bash test=false
$ kubectl get nodes --watch
```

If you want to wait until the MNG is updated you can run the following command:

```bash timeout=900
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

Once this is completed, you can proceed to the next step.