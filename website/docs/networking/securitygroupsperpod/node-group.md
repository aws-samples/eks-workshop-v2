---
title: "Provision Managed Node Group"
sidebar_position: 40
weight: 40
---

Security groups for pods are supported by most Nitro-based Amazon EC2 instance families, including the m5, c5, r5, p3, m6g, c6g, and r6g instance families. The t3 instance family is not supported and so we will create a second NodeGroup using one m5.large instance.

### 1. Configure Target Subnets

Use the following commands to configure the target subnets:
TODO: FIX `subnetlist` variable

```bash
$ az_1=`echo $subnetlist | jq -r '.[0][0]'`

$ new_subnet_id_1=`echo $subnetlist | jq -r '.[0][1]'`

$ az_2=`echo $subnetlist | jq -r '.[1][0]'`

$ new_subnet_id_2=`echo $subnetlist | jq -r '.[1][1]'`

$ az_3=`echo $subnetlist | jq -r '.[2][0]'`

$ new_subnet_id_3=`echo $subnetlist | jq -r '.[2][1]'`
```

### 2. Create IAM Role

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

### 3. Create Node Group

Use the following command to create the group:

```bash
$ aws eks create-nodegroup --region ${AWS_DEFAULT_REGION} \
--cluster-name ${EKS_CLUSTER_NAME} \
--nodegroup-name nodegroup-sec-group \
--subnets ${new_subnet_id_1} ${new_subnet_id_2} ${new_subnet_id_3} \
--instance-types m5.large --node-role ${node_role_arn} \
--scaling-config minSize=1,maxSize=3,desiredSize=3
```

Node group creation takes several minutes. You can check the status of the creation of a managed node group with the following command.

```bash
$ aws eks describe-nodegroup --cluster-name ${cluster_name} \
--nodegroup-name nodegroup-sec-group \
--query nodegroup.status --output text
```

**NOTE: Don't continue to the next step until the output returned is ACTIVE.**

Get a list of nodes in your cluster:

```bash
$ kubectl get nodes -o wide
```

You can see that 3 new nodes are provisioned in the 10.42.0.0/16 CIDR range.

