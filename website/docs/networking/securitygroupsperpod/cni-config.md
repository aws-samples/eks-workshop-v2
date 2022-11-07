---
title: "Configure Amazon VPC CNI"
sidebar_position: 30
weight: 30
---

To utilize the Security Groups for Pods feature, the Amazon VPC CNI needs to be configured using the following steps. Note: The VPC CNI configuration change is required if you have Amazon EC2 nodes in your cluster. If you aim to use security groups for Fargate pods only, this configuration is not required.

### CNI Plugin Version Check

Check your CNI plugin version with the following command:

```bash
$ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
```

Here is an example output. If the add-on version displayed is earlier than 1.7.7, update the CNI plugin to version  1.7.7 or later.

```
amazon-k8s-cni-init:v1.11.4-eksbuild.1
amazon-k8s-cni:v1.11.4-eksbuild.1
```

For more information, see [Updating the Amazon VPC CNI plugin for Kubernetes add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#updating-vpc-cni-eks-add-on).

### Update Cluster Role

To allow the management of network interfaces, their private IP addresses, and their attachment and detachment to and from network instances, the cluster role associated to the Amazon EKS cluster needs to be updated. Adding the managed policy `AmazonEKSVPCResourceController` to the role fulfills this requirement.

i. Determine the ARN of your cluster IAM role.
```bash
$ aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query cluster.roleArn --output text
```

The example output is as follows:

```
arn:aws:iam::111122223333:role/eks-workshop-cluster-cluster-role
```

ii. The following command adds the policy to a cluster role. *Replace `<eksClusterRole>` with the name of your role.*

```bash
$ aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController \
    --role-name <eksClusterRole>
```

### Update CNI Plugin Config

Enable the Amazon VPC CNI add-on to manage network interfaces for pods by setting the `ENABLE_POD_ENI` variable to `true` in the `aws-node` DaemonSet.

```bash
$ kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true
```

You can see which of your nodes have `aws-k8s-trunk-eni` set to true with the following command.

```bash
$ kubectl get nodes -o wide -l vpc.amazonaws.com/has-trunk-attached=true
```

Note: *If `No resources found` is returned, then wait several seconds and try again. The previous step requires restarting the CNI pods, which takes several seconds.*

#### Additional CNI Plugin Config for version 1.11.0 or later

If the output of the CNI plugin version check showed a version 1.11.0 or later, the following additional configuration is required.

```bash
$ kubectl set env daemonset aws-node -n kube-system POD_SECURITY_GROUP_ENFORCING_MODE=standard
```
