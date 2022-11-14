---
title: "Configure Amazon VPC CNI"
sidebar_position: 30
weight: 30
---

To utilize the Security Groups for Pods feature, the Amazon VPC CNI needs to be configured using the following steps. Note: The VPC CNI configuration change is required if you have Amazon EC2 nodes in your cluster. If you aim to use security groups for Fargate pods only, this configuration is not required.

Check your CNI plugin version with the following command:

```bash
$ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
amazon-k8s-cni-init:v1.11.4-eksbuild.1
amazon-k8s-cni:v1.11.4-eksbuild.1
```

For more information, see [Updating the Amazon VPC CNI plugin for Kubernetes add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#updating-vpc-cni-eks-add-on).

To allow the management of network interfaces, their private IP addresses, and their attachment and detachment to and from network instances, the cluster role associated to the Amazon EKS cluster needs to be updated. Adding the managed policy `AmazonEKSVPCResourceController` to the role fulfills this requirement. The cluster set up for you as part of this workshop is already configured with that role. Lets take a look.

```bash
$ aws iam list-attached-role-policies \
    --role-name ${EKS_CLUSTER_NAME}-cluster-role
```

Enable the Amazon VPC CNI add-on to manage network interfaces for pods by setting the `ENABLE_POD_ENI` variable to `true` and `POD_SECURITY_GROUP_ENFORCING_MODE` to `standard` in the `aws-node` DaemonSet.

```bash
$ kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true POD_SECURITY_GROUP_ENFORCING_MODE=standard
```

You can see which of your nodes have `aws-k8s-trunk-eni` set to true with the following command.

```bash
$ kubectl get nodes -o wide -l vpc.amazonaws.com/has-trunk-attached=true
```