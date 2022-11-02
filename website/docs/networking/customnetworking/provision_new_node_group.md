---
title: "Provision a new Node Group"
sidebar_position: 5
weight: 40
---

Create a node IAM role.

Run the following command to create an IAM trust policy JSON file.

```bash expectError=true
cat >node-role-trust-relationship.json <<EOF
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
export node_role_name=eksCustomNetworkingAmazonEKSNodeRole
```

Create the IAM role and store its returned Amazon Resource Name (ARN) in a variable for use in a later step.

```bash expectError=true
node_role_arn=$(aws iam create-role --role-name $node_role_name --assume-role-policy-document file://"node-role-trust-relationship.json" \
    --query Role.Arn --output text)
```

Attach three required IAM managed policies to the IAM role.

```bash expectError=true
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --role-name $node_role_name
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --role-name $node_role_name
aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
    --role-name $node_role_name
```

Create a Managed Node Group

```bash expectError=true
aws eks create-nodegroup --region $region_code --cluster-name $cluster_name --nodegroup-name custom-networking-nodegroup \
 --subnets $new_subnet_id_1 $new_subnet_id_2 $new_subnet_id_3 --instance-types t3.medium --node-role $node_role_arn --scaling-config minSize=1,maxSize=3,desiredSize=3
```

Node group creation takes several minutes. You can check the status of the creation of a managed node group with the following command.

```bash expectError=true
aws eks describe-nodegroup --cluster-name $cluster_name --nodegroup-name custom-networking-nodegroup --query nodegroup.status --output text
```

Don't continue to the next step until the output returned is ACTIVE.

Get a list of nodes in your cluster

```bash expectError=true
kubectl get nodes -o wide
```

TODO - Show kubectl output

You can see that 3 new nodes are provisioned in the 100.64.0.0/16 CIDR range.


