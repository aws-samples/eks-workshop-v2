---
title: "Provision Managed Node Group"
sidebar_position: 40
weight: 40
---

Security groups for pods are supported by most Nitro-based Amazon EC2 instance families, including the m5, c5, r5, p3, m6g, c6g, and r6g instance families. The t3 instance family is not supported and so we will create a second NodeGroup using one m5.large instance.

### 1. Create IAM Role

Run the following command to create an IAM trust policy JSON file.

```bash
$ cat >node-role-trust-relationship-2.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

Export a role name using:

```bash
$ export node_role_name=eksSGForPodsAmazonEKSNodeRole
```

Create the IAM role and store its returned Amazon Resource Name (ARN) in a variable for use in a later step.

```bash
$ node_role_arn=$(aws iam create-role --role-name ${node_role_name} \
--assume-role-policy-document file://"node-role-trust-relationship-2.json" \
--query Role.Arn --output text)
```

Attach three required IAM managed policies to the IAM role.

```bash
$ aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --role-name $node_role_name

$ aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --role-name $node_role_name

$ aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
    --role-name $node_role_name
```

### 2. Create Node Group

Use the following command to create the group:

```bash
$ aws eks create-nodegroup --region ${AWS_DEFAULT_REGION} \
--cluster-name ${EKS_CLUSTER_NAME} \
--nodegroup-name nodegroup-sec-group \
--subnets ${PRIMARY_SUBNET_1} ${PRIMARY_SUBNET_2} ${PRIMARY_SUBNET_3} \
--instance-types m5.large --node-role ${node_role_arn} \
--scaling-config minSize=1,maxSize=3,desiredSize=3
```

Node group creation takes several minutes. You can check the status of the creation of a managed node group with the following command.

```bash
$ aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} \
--nodegroup-name nodegroup-sec-group \
--query nodegroup.status --output text
```

**NOTE: Don't continue to the next step until the output returned is ACTIVE.**

Get a list of nodes in your cluster:

```bash
$ kubectl get nodes -o wide
```

Here is a sample output from the previous command.

```bash
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE    VERSION               INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-42-10-93.us-west-2.compute.internal     Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.10.93     <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-11-6.us-west-2.compute.internal      Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.11.6      <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-12-60.us-west-2.compute.internal     Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.12.60     <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-10-224.us-west-2.compute.internal    Ready    <none>   104s   v1.23.9-eks-ba74326   10.42.10.224    <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-11-228.us-west-2.compute.internal    Ready    <none>   105s   v1.23.9-eks-ba74326   10.42.11.228    <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-12-220.us-west-2.compute.internal    Ready    <none>   105s   v1.23.9-eks-ba74326   10.42.12.220    <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
```

You can see that 3 new nodes are provisioned in the `10.42.0.0/16` CIDR range.
