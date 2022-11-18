---
title: "Launch Bottlerocket nodes to an EKS cluster"
sidebar_position: 53
---

## Add Bottlerocket nodes to an EKS cluster

Create an environment variables "eks_vpc_id" and "eks_subnet_id". We will use this in the next step:

```bash
$ vpc_id=$(aws eks describe-cluster --name eks-workshop-cluster --query 'cluster.resourcesVpcConfig.vpcId')
$ export eks_vpc_id=$(echo $vpc_id | tr -d '"')
$ subnet_id=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId | [0]')
$ export eks_subnet_id=$(echo $subnet_id | tr -d '"')
```

Create EKS trust policy using the following command to create Bottlerocket nodegroup IAM Role. Also, set the "EKS_IAM_NODE_ROLE" environment variable:

```bash
cat << EOF > eks-trust-policy.json
---
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
               "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        },
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

$ export EKS_IAM_NODE_ROLE=$(aws iam create-role --role-name EKS_IAM_NODE_ROLE --assume-role-policy-document file://eks-trust-policy.json)
```

Add the required policies to the "EKS_IAM_NODE_ROLE" managed role using the following commands:

```bash
$ aws iam attach-role-policy --role-name EKS_IAM_NODE_ROLE --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
$ aws iam attach-role-policy --role-name EKS_IAM_NODE_ROLE --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy 
$ aws iam attach-role-policy --role-name EKS_IAM_NODE_ROLE --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

Next, run the following command to confirm the new application is running on the bottlerocket node:

```bash
$ aws eks create-nodegroup --cluster-name eks-workshop-cluster --nodegroup-name btl-x86 --subnets $eks_subnet_id --node-role $EKS_IAM_NODE_ROLE --ami-type BOTTLEROCKET_x86_64 --scaling-config minSize=1,maxSize=1,desiredSize=1 --labels "role"="bottlerocket"
 ```

Next, run the following command to list all the nodes in the EKS cluster and you should see a node as follows:

```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-42-0-133.us-west-2.compute.internal   Ready    <none>   15h   v1.23.12-eks-a64d4ad
```

