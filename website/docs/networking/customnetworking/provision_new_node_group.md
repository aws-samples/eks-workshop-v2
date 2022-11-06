---
title: "Provision a new Node Group"
sidebar_position: 20
weight: 40
---

Create a node IAM role.

Run the following command to create an IAM trust policy JSON file.

```bash expectError=true
$ cat >node-role-trust-relationship.json <<EOF
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

Run the following command to set a variable for your role name

```bash expectError=true
$ export node_role_name=eksCustomNetworkingAmazonEKSNodeRole
```

Create the IAM role and store its returned Amazon Resource Name (ARN) in a variable for use in a later step.

```bash expectError=true
$ node_role_arn=$(aws iam create-role --role-name $node_role_name --assume-role-policy-document file://"node-role-trust-relationship.json" \
    --query Role.Arn --output text)
```

Attach three required IAM managed policies to the IAM role.

```bash expectError=true
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

Create a Managed Node Group

```bash expectError=true
$ aws eks create-nodegroup --region $AWS_DEFAULT_REGION --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking-nodegroup \
  --subnets $SECONDARY_SUBNET_1 $SECONDARY_SUBNET_2 $SECONDARY_SUBNET_3 \
  --instance-types t3.medium --node-role $node_role_arn \
  --scaling-config minSize=1,maxSize=3,desiredSize=3
```

Node group creation takes several minutes. You can check the status of the creation of a managed node group with the following command.

```bash expectError=true
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup --query nodegroup.status --output text
```

Don't continue to the next step until the output returned is ACTIVE.

Get a list of nodes in your cluster

```bash expectError=true
$ kubectl get nodes -o wide
```

Here is a sample output from the previous command.
```bash expectError=true
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE    VERSION               INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-42-10-93.us-west-2.compute.internal     Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.10.93     <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-11-6.us-west-2.compute.internal      Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.11.6      <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-12-60.us-west-2.compute.internal     Ready    <none>   2d3h   v1.23.9-eks-ba74326   10.42.12.60     <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-100-64-10-224.us-west-2.compute.internal   Ready    <none>   104s   v1.23.9-eks-ba74326   100.64.10.224   <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-100-64-11-228.us-west-2.compute.internal   Ready    <none>   105s   v1.23.9-eks-ba74326   100.64.11.228   <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-100-64-12-220.us-west-2.compute.internal   Ready    <none>   105s   v1.23.9-eks-ba74326   100.64.12.220   <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
```

You can see that 3 new nodes are provisioned in the 100.64.0.0/16 CIDR range.


