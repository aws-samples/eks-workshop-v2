---
title: "Security Groups for Pods"
sidebar_position: 20
weight: 10
sidebar_custom_props: { "module": true }
description: "Control inbound and outbound traffic to and from pods on Amazon Elastic Kubernetes Service with Amazon EC2 security groups."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=30
$ prepare-environment networking/securitygroups-for-pods
```

This will make the following changes to your lab environment:

- Create an Amazon Relational Database Service instance
- Create an Amazon EC2 security group to allow access to the RDS instance

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/securitygroups-for-pods/.workshop/terraform).

:::

Security groups, acting as instance level network firewalls, are among the most important and commonly used building blocks in any AWS cloud deployment. Containerized applications frequently require access to other services running within the cluster as well as external AWS services, such as Amazon Relational Database Service (Amazon RDS) or Amazon ElastiCache. On AWS, controlling network level access between services is often accomplished via EC2 security groups.

By default, the Amazon VPC CNI will use security groups associated with the primary ENI on the node. More specifically, every ENI associated with the instance will have the same EC2 Security Groups. Thus, every Pod on a node shares the same security groups as the node it runs on. Security groups for Pods make it easy to achieve network security compliance by running applications with varying network security requirements on shared compute resources. Network security rules that span Pod to Pod and Pod to external AWS service traffic can be defined in a single place with EC2 security groups, and applied to applications with Kubernetes native APIs. After applying security groups at the Pod level, your application and node group architecture can be simplified as shown below.

You can enable security groups for Pods by setting `ENABLE_POD_ENI=true` for VPC CNI. When you enable Pod ENI, the [VPC Resource Controller](https://github.com/aws/amazon-vpc-resource-controller-k8s) running on the control plane (managed by EKS) creates and attaches a trunk interface called "aws-k8s-trunk-eni" to the node. The trunk interface acts as a standard network interface attached to the instance.

The controller also creates branch interfaces named "aws-k8s-branch-eni" and associates them with the trunk interface. Pods are assigned a security group using the [SecurityGroupPolicy](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/config/crd/bases/vpcresources.k8s.aws_securitygrouppolicies.yaml) custom resource and are associated with a branch interface. Since security groups are specified with network interfaces, we're now able to schedule Pods requiring specific security groups on these additional network interfaces. Review [EKS best practices guide](https://aws.github.io/aws-eks-best-practices/networking/sgpp/) for recommendations and [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html) for deployment prerequisites.

![Insights](/docs/networking/vpc-cni/security-groups-for-pods/overview.webp)

In this chapter we'll re-configure one of the sample application components to leverage security groups for Pods to access an external network resource.
