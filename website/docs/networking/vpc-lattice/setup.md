---
title: "VPC Lattice Setup"
sidebar_position: 10
---

# Deploying the AWS Gateway API Controller

Follow these instructions to create a cluster and deploy the AWS Gateway API Controller.

First, configure security group to receive traffic from the VPC Lattice fleet. You must set up security groups so that they allow all Pods communicating with VPC Lattice to allow traffic on all ports from the `169.254.171.0/24` address range. See [Control traffic to resources using security groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) for details. You can use the following managed prefix to provide the values:

```bash
$ PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_DEFAULT_REGION.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
$ MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')
$ CLUSTER_SG=$(aws eks describe-cluster --name eks-workshop --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --cidr $MANAGED_PREFIX --protocol -1
```

Create a policy (`recommended-inline-policy.json`) in IAM with the following content that can invoke the gateway API and copy the policy arn for later use:

```bash
$ aws iam create-policy \
--policy-name VPCLatticeControllerIAMPolicy \
--policy-document file://workspace/modules/networking/vpc-lattice/controller/recommended-inline-policy.json
```

```file
/networking/vpc-lattice/controller/recommended-inline-policy.json
```

Create the `system` namespace:
```bash
$ kubectl apply -f workspace/modules/networking/vpc-lattice/controller/deploy-namesystem.yaml
```
Retrieve the policy ARN:
```bash
$ export VPCLatticeControllerIAMPolicyArn=$(aws iam list-policies --query 'Policies[?PolicyName==`VPCLatticeControllerIAMPolicy`].Arn' --output text)
```
Create an `iamserviceaccount` for pod level permission:
```bash
$ eksctl create iamserviceaccount \
    --cluster=${EKS_CLUSTER_NAME} \
    --namespace=system \
    --name=gateway-api-controller \
    --attach-policy-arn=${VPCLatticeControllerIAMPolicyArn} \
    --override-existing-serviceaccounts \
    --region ${AWS_DEFAULT_REGION} \
    --approve
```

Run either `kubectl` or `helm` to deploy the controller:

```bash
$ kubectl apply -f workspace/modules/networking/vpc-lattice/controller/deploy-resources.yaml
```
      
**or**

Login to ECR:
```bash
$ aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
```
And run `helm` with either install or upgrade

```bash
$ helm install gateway-api-controller \
    oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart\
    --version=v0.0.7 \
    --set=aws.region=${AWS_DEFAULT_REGION} --set=serviceAccount.create=false --namespace system
```

Create the `amazon-vpc-lattice` GatewayClass:
```bash
$ kubectl apply -f workspace/modules/networking/vpc-lattice/controller/gatewayclass.yaml
```