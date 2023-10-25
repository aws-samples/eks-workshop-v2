---
title: "Deploy the Controller"
sidebar_position: 10
---

# Deploying the AWS Gateway API Controller

Follow these instructions to create a cluster and deploy the AWS Gateway API Controller.

First, configure security group to receive traffic from the VPC Lattice fleet. You must set up security groups so that they allow all Pods communicating with VPC Lattice to allow traffic on all ports from the `169.254.171.0/24` address range for IPv4 and the `fd00:ec2:80::/64` address range for IPv6. See [Control traffic to resources using security groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) for details. You can use the following managed prefix to provide the values:

```bash
$ CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
$ IPV4_PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
$ IPV4_MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $IPV4_PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --cidr $IPV4_MANAGED_PREFIX --protocol -1
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-07edb399e8903357b",
            "GroupId": "sg-047f384df6b944788",
            "GroupOwnerId": "364959265732",
            "IsEgress": false,
            "IpProtocol": "-1",
            "FromPort": -1,
            "ToPort": -1,
            "CidrIpv4": "169.254.171.0/24"
        }
    ]
}
$ IPV6_PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
$ IPV6_MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $IPV6_PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG \
  --ip-permissions IpProtocol=-1,FromPort=-1,ToPort=-1,Ipv6Ranges="[{CidrIpv6=$IPV6_MANAGED_PREFIX}]"
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0eeda91601cbafbfa",
            "GroupId": "sg-047f384df6b944788",
            "GroupOwnerId": "364959265732",
            "IsEgress": false,
            "IpProtocol": "-1",
            "FromPort": -1,
            "ToPort": -1,
            "CidrIpv6": "fd00:ec2:80::/64"
        }
    ]
}
```

This step will install the controller and the CRDs (Custom Resource Definitions) required to interact with the Kubernetes Gateway API.

```bash wait=30
$ aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install gateway-api-controller \
    oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart \
    --version=v0.0.16 \
    --create-namespace \
    --set=aws.region=${AWS_REGION} \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LATTICE_IAM_ROLE" \
    --namespace gateway-api-controller \
    --wait
```

The controller will now be running as a deployment:

```bash
$ kubectl get deployment -n gateway-api-controller
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
gateway-api-controller-aws-gateway-controller-chart   2/2     2            2           24s
```