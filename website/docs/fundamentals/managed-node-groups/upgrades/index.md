---
title: Upgrade Managed Node Group
sidebar_position: 60
---

Amazon EKS gives the end users the flexibility to deploy nodes either with Amazon Linux AMI's or build your own custom AMI's, When you initiate a managed node group update. Amazon EKS automatically update your nodes by applying the latest security patches and OS updates.

Below are the list of the supported Node OS:

* [Amazon Linux Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
* [Ubuntu Linux](https://docs.aws.amazon.com/eks/latest/userguide/eks-partner-amis.html) 
* [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html)
* [Windows](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-windows-ami.html)


For More Information on the latest AMI release versions:

[Amazon Linux AMI](https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md) || [Bottlerocket AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html) || [Windows AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html)


**Note:** Starting with kubernetes version 1.24, Amazon EKS will end the support for `Dockershim`. The only runtime available would be
`containerd`.

There are two ways to provision and upgrade your worker nodes - self-managed node groups and managed node groups. In this workshop eksctl was configured to use the managed node groups. This was helpful here as managed node groups make this easier for us by automating both the AWS and the Kubernetes side of the process.

* Amazon EKS creates a new Amazon EC2 launch template version for the Auto Scaling group associated with your node group. The new template uses the target AMI for the update.
* The Auto Scaling group is updated to use the latest launch template with the new AMI.
* The Auto Scaling group maximum size and desired size are incremented by one up to twice the number of Availability Zones in the Region that the Auto Scaling group is deployed in. This is to ensure that at least one new instance comes up in every Availability Zone in the Region that your node group is deployed in.
Amazon EKS checks the nodes in the node group for the eks.amazonaws.com/nodegroup-image label, and applies a eks.amazonaws.com/nodegroup=unschedulable:NoSchedule taint on all of the nodes in the node group that aren’t labeled with the latest AMI ID. This prevents nodes that have already been updated from a previous failed update from being tainted.
* Amazon EKS randomly selects a node in the node group and evicts all pods from it.
* After all of the pods are evicted, Amazon EKS cordons the node. This is done so that the service controller doesn’t send any new request to this node and removes this node from its list of healthy, active nodes.
* Amazon EKS sends a termination request to the Auto Scaling group for the cordoned node.
* Steps 5-7 are repeated until there are no nodes in the node group that are deployed with the earlier version of the launch template.
* The Auto Scaling group maximum size and desired size are decremented by 1 to return to your pre-update values.


To trigger the MNG upgrade process, Run the following eksctl command:

```bash
$ eksctl upgrade nodegroup --name=nodegroup --cluster=$EKS_CLUSTER_NAME --kubernetes-version=1.23
```

In another Terminal tab you can follow the progress with:

```bash
$ kubectl get nodes --watch
```

