---
title: "Security Groups per Pod"
sidebar_position: 30
weight: 10
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

An AWS security group acts as a virtual firewall for EC2 instances to control inbound and outbound traffic. By default, the Amazon VPC CNI will use security groups associated with the primary ENI on the node. More specifically, every ENI associated with the instance will have the same EC2 Security Groups. Thus, every Pod on a node shares the same security groups as the node it runs on.

You can enable security groups for Pods by setting `ENABLE_POD_ENI=true` for VPC CNI. When you enable Pod ENI, the [VPC Resource Controller](https://github.com/aws/amazon-vpc-resource-controller-k8s) running on the control plane (managed by EKS) creates and attaches a trunk interface called “aws-k8s-trunk-eni“ to the node. The trunk interface acts as a standard network interface attached to the instance.

The controller also creates branch interfaces named "aws-k8s-branch-eni" and associates them with the trunk interface. Pods are assigned a security group using the [SecurityGroupPolicy](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/config/crd/bases/vpcresources.k8s.aws_securitygrouppolicies.yaml) custom resource and are associated with a branch interface. Since security groups are specified with network interfaces, we are now able to schedule Pods requiring specific security groups on these additional network interfaces. Review [EKS best practices guide](https://aws.github.io/aws-eks-best-practices/networking/sgpp/) for recommendations and [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html), for deployment prerequisites.

![Insights](/img/networking/securitygroupsperpod/overview.png)
