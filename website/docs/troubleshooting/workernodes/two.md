---
title: "Node Join Failure"
sidebar_position: 72
chapter: true
---

::required-time

### Background

Corporation XYZ's e-commerce platform has been steadily growing, and the engineering team has decided to expand the EKS cluster to handle the increased workload. The team plans to create a new subnet in the us-west-2 region and provision a new managed node group under this subnet.

Sam, an experienced DevOps engineer, has been tasked with executing this expansion plan. Sam begins by creating a new VPC subnet in the us-west-2 region, with a new CIDR block. The goal is to have the new managed node group run the application workloads in this new subnet, separate from the existing node groups.

After creating the new subnet, Sam proceeds to configure the new managed node group _*new_nodegroup_2*_ in the EKS cluster. During the node group creation process, Sam notices that the new nodes are not visible in the EKS cluster and not joining the cluster.

### Step 1: Verify Node Status

1. Let's first verify if the new nodes from nodegroup _new_nodegroup_2_ are visible in the cluster:

```bash timeout=30 hook=fix-2-1 hookTimeout=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
No resources found
```

### Step 2: Check Managed Node Group Status

Let's examine the EKS managed node group configuration to verify its status and configuration:

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_2 --query 'nodegroup.{nodegroupName:nodegroupName,nodegroupArn:nodegroupArn,clusterName:clusterName,status:status,capacityType:capacityType,scalingConfig:scalingConfig,health:{issues:health.issues}}'
```

Output:

```json {7,12,15-16}
{
    "nodegroup": {
        "nodegroupName": "new_nodegroup_2",
        "nodegroupArn": "arn:aws:eks:us-west-2:1234567890:nodegroup/eks-workshop/new_nodegroup_2/abcd1234-1234-abcd-1234-1234abcd1234",
        "clusterName": "eks-workshop",
        ...
        "status": "ACTIVE",
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 0,
            "maxSize": 1,
            "desiredSize": 1
        },
        ...
        "health": {
            "issues": []
```

:::info
Alternatively, you can also check the console for the same. Click the button below to open the EKS Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="Open EKS Cluster Compute Tab"
/>
:::

Key observations from the output:

- Node group status is ACTIVE
- Desired capacity is 1
- No health issues reported
- Scaling configuration is correct

### Step 3: Investigate Auto Scaling Group

Let's check the ASG activities to understand the instance launch status:

#### 3.1. Identify Nodegroup's Auto Scaling Group Name

Run the below command to capture Nodegroup Autoscale Group name as NEW_NODEGROUP_2_ASG_NAME.

```bash
$ NEW_NODEGROUP_2_ASG_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1 --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
echo $NEW_NODEGROUP_2_ASG_NAME
```
#### 4.2. Check the AutoScaling Activities

```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_2_ASG_NAME} --query 'Activities[*].{AutoScalingGroupName:AutoScalingGroupName,Description:Description,Cause:Cause,StatusCode:StatusCode}'
```

Output:

```json {6,11}
{
    "Activities": [
        {
            "ActivityId": "1234abcd-1234-abcd-1234-1234abcd1234",
            "AutoScalingGroupName": "eks-new_nodegroup_2-abcd1234-1234-abcd-1234-1234abcd1234",
    --->>>  "Description": "Launching a new EC2 instance: i-1234abcd1234abcd1",
            "Cause": "At 2024-10-09T14:59:26Z a user request update of AutoScalingGroup constraints to min: 0, max: 2, desired: 1 changing the desired capacity from 0 to 1.  At 2024-10-09T14:59:36Z an instance was started in response to a difference between desired and actual capacity, increasing the capacity from 0 to 1.",
            ...
    --->>>  "StatusCode": "Successful",
            ...
        }
    ]
}
```

:::info
You can check the EKS console as well. Click the Autoscaling group name to open the ASG console view ASG activity.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_2"
  service="eks"
  label="Open EKS cluster Nodegroup Tab"
/>
:::

Key findings:

- Instance launch was successful
- ASG reports normal operation
- Desired capacity changes were processed

### Step 4: Examine EC2 Instance Configuration

Let's inspect the launched EC2 instance configuration:

:::info
**Note:** _For your convenience we have added the instance ID as env variable with the variable `$NEW_NODEGROUP_2_INSTANCE_ID`._
:::

```bash
$ aws ec2 describe-instances --instance-ids $NEW_NODEGROUP_2_INSTANCE_ID --query 'Reservations[*].Instances[*].{InstanceState: State.Name, SubnetId: SubnetId, VpcId: VpcId, InstanceProfile: IamInstanceProfile, SecurityGroups: SecurityGroups}' --output json
```

Output:

```json {4,8,14}
[
  [
    {
      "InstanceState": "running",
      "SubnetId": "subnet-1234abcd1234abcd1",
      "VpcId": "vpc-1234abcd1234abcd1",
      "InstanceProfile": {
        "Arn": "arn:aws:iam::1234567890:instance-profile/eks-abcd1234-1234-abcd-1234-1234abcd1234",
        "Id": "ABCDEFGHIJK1LMNOP2QRS"
      },
      "SecurityGroups": [
        {
          "GroupName": "eks-cluster-sg-eks-workshop-123456789",
          "GroupId": "sg-1234abcd1234abcd1"
        }
      ]
    }
  ]
]
```

Important aspects to verify:

- Instance state is "running"
- Instance profile and IAM role assignments
- Security group configurations
  :::info
  To use the console, click the button below to open the EC2 Console.
  <ConsoleButton
    url="https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:instanceState=running;search=troubleshooting-two-eks-workshop"
    service="ec2"
    label="Open EC2 Console"
  />
  :::

### Step 5: Analyze Network Configuration

Let's examine the subnet and routing configuration:

:::info
**Note:** _For your convenience Subnet ID is added as env variable `$NEW_NODEGROUP_2_SUBNET_ID`._
:::

#### 5.1. Check subnet configuration

```bash
$ aws ec2 describe-subnets --subnet-ids $NEW_NODEGROUP_2_SUBNET_ID --query 'Subnets[*].{AvailabilityZone: AvailabilityZone, AvailableIpAddressCount: AvailableIpAddressCount, CidrBlock: CidrBlock, State: State}'
```

Output:

```json {4}
[
  {
    "AvailabilityZone": "us-west-2a",
    "AvailableIpAddressCount": 8186,
    "CidrBlock": "10.42.192.0/19",
    "State": "available"
  }
]
```

#### 5.2. Obtain route table ID

```bash
$ aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$NEW_NODEGROUP_2_SUBNET_ID" \
  --query "RouteTables[*].{RouteTableId:RouteTableId,AssociatedSubnets:Associations[*].SubnetId}"
```

Output:

```json {4}
[
  {
    "RouteTableId": "rtb-1234abcd1234abcd1",
    "AssociatedSubnets": ["subnet-1234abcd1234abcd1"]
  }
]
```

#### 5.3. Examine route table configuration

:::info
**Note:** _For your convenience Subnet ID is added as env variable `$NEW_NODEGROUP_2_ROUTETABLE_ID`._
:::

```bash timeout=15 hook=fix-2-2 hookTimeout=20
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[0].Routes'
```

Output:

```json {4}
[
  {
    "DestinationCidrBlock": "10.42.0.0/16",
    "GatewayId": "local",
    "Origin": "CreateRouteTable",
    "State": "active"
  }
]
```

:::info
To use the VPC console click the button. Check the Subnet Details tab, and Route tables tab for route table routes.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

:::note
**Critical Finding**: Route table shows only local routes (10.42.0.0/16) with no internet access path
:::

### Step 6: Implement Solution

The root cause is identified as missing internet access for the worker nodes. Let's implement the fix:

:::info
**Note:** _For your convenience NatGateway ID is added as env variable `$DEFAULT_NODEGROUP_NATGATEWAY_ID`._
:::

#### 6.1. Add NAT Gateway route

```bash
$ aws ec2 create-route --route-table-id $NEW_NODEGROUP_2_ROUTETABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $DEFAULT_NODEGROUP_NATGATEWAY_ID
```

Output:

```json {}
{
  "Return": true
}
```

#### 6.2. Verify the new route

```bash
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[*].{RouteTableId:RouteTableId,VpcId:VpcId,Routes:Routes}'
```

Output:

```json {13,14}
[
    {
        "RouteTableId": "rtb-1234abcd1234abcd1",
        "VpcId": "vpc-1234abcd1234abcd1",
        "Routes": [
            {
                "DestinationCidrBlock": "10.42.0.0/16",
                "GatewayId": "local",
                "Origin": "CreateRouteTable",
                "State": "active"
            },
            {
                "DestinationCidrBlock": "0.0.0.0/0",            <<<---
                "NatGatewayId": "nat-1234abcd1234abcd1",        <<<---
                "Origin": "CreateRoute",
                "State": "active"
            }
        ]
    }
]

```

:::info
Click the button below to use the VPC Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

#### 6.3. Recycle the node group to trigger new instance launch

Scale down and scale up the node group. This can take up to 1 minute.

```bash timeout=120 wait=90
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=0 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 && aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2
```

### Step 7: Verification

Verify the node has successfully joined the cluster:

```bash timeout=100 hook=fix-2-3 hookTimeout=110 wait=70
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

:::info
Newly joined node can take up to about 1 minute to show.
:::

### Key Takeaways

#### Network Requirements

- Worker nodes require internet access for AWS service communication
- NAT Gateway provides secure outbound connectivity
- Route table configuration is critical for node bootstrapping

#### Troubleshooting Approach

- Verify node group configuration
- Check instance status
- Analyze network configuration
- Examine routing tables

#### Best Practices

- Implement proper network planning
- Use private subnets with NAT Gateway
- Follow AWS security best practices
- Consider VPC endpoints for enhanced security

### Additional Resources

#### Security and Access Control

- [Security Group Requirements](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#security-group-restricting-cluster-traffic) - Essential security group rules and configurations required for EKS cluster communication
- [AWS User Guide for Private Clusters](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html) - Comprehensive guide for setting up and managing private EKS clusters
- [Configuring Private Access to AWS Services](https://eksctl.io/usage/eks-private-cluster/#configuring-private-access-to-additional-aws-services) - Detailed instructions for configuring private access to AWS services using VPC endpoints - eksctl

#### Best Practices Documentation

- [EKS Networking Best Practices](https://docs.aws.amazon.com/eks/latest/best-practices/networking.html) - AWS recommended networking practices for EKS cluster design and operation
- [VPC Endpoint Services Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) - Complete guide to implementing and managing VPC endpoints for secure service access

:::tip
For a comprehensive understanding of EKS networking, review the [EKS Networking Documentation](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html). For a troubleshooting guide, review the [Knowledge Center article](https://repost.aws/knowledge-center/eks-worker-nodes-cluster).
:::
