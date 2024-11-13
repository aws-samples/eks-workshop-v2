---
title: "Node Join Failure"
sidebar_position: 31
chapter: true
sidebar_custom_props: { "module": true }
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=30
$ prepare-environment troubleshooting/workernodes/two
```

The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:

- Create a new managed node group called **_new_nodegroup_2_**
- Introduce a problem to the managed node group which causes node to **_not join_**
- Set desired managed node group count to 1

:::

### Background

Corporate XYZ's e-commerce platform has been steadily growing, and the engineering team has decided to expand the EKS cluster to handle the increased workload. The team plans to create a new subnet in the us-west-2 region and provision a new managed node group under this subnet.

Sam, an experienced DevOps engineer, has been tasked with executing this expansion plan. Sam begins by creating a new VPC subnet in the us-west-2 region, with a new CIDR block. The goal is to have the new managed node group run the application workloads in this new subnet, separate from the existing node groups.

After creating the new subnet, Sam proceeds to configure the new managed node group **_new_node_group_2_** in the EKS cluster. During the node group creation process, Sam notices that the new nodes are not visible in the EKS cluster and not joining the cluster.

Can you help Sam identify the root cause of the node group issue and suggest the necessary steps to resolve the problem, so the new nodes can join the cluster?

### Step 1

1. First let's confirm and verify what you have learned from the engineer to see if there are any nodes.

```bash timeout=30 hook=fix-2-1 hookTimeout=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
No resources found
```

As you can see, there are no resources found for nodes launched from the new nodegroup (new_nodegroup_2).

### Step 2

Now that we know there are no nodes joined to the cluster, we can confirm if the worker node itself has been created or not. This can first be done by checking the managed nodegroup new_node_group_2 for its health and proper configurations.

Some important and basic details to keep an eye out for are:

- Does the nodegroup exist?
- Managed Node Group Status and health
- Desired size

```bash
$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_2
```

:::info
Alternatively, you can also check the console for the same. Click the button below to open the EKS Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="Open EKS Cluster Compute Tab"
/>
:::

### Step 3

As you have seen from the output, the managed nodegroup appears to be without any issues. We can confirm the managed nodegroup exists, the status is in ACTIVE state, desired count is at 1, and there are no health issues.

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

Now that we've confirmed that the nodegroup exists, we can narrow this down further by checking the Autoscaling Group (ASG) which is the AWS component that performs scaling activities for the node.

:::info
**Note:** _For your convenience we have added the Autoscaling Group name as env variable with the variable `$NEW_NODEGROUP_2_ASG_NAME`._
:::

```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_2_ASG_NAME} --query 'Activities[*].{AutoScalingGroupName:AutoScalingGroupName,Description:Description,Cause:Cause,StatusCode:StatusCode}'

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
Alternatively, you can also check the console for the same. Click the button below to open the EKS Console. You can find the Autoscaling group name under the Details tab of the node group. Then you can click the Autoscaling group name to redirect to the ASG console. Then click the Activity tab to view the ASG activty history.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_2"
  service="eks"
  label="Open EKS cluster Nodegroup Tab"
/>
:::

We see one activity and it looks like an ec2 instance was launched successfully. Now let's dive deeper into the instance to check further. Major things to consider when troubleshooting join issues are:

- Permissions (e.g. Instance Role permissions)
- Network Configurations (e.g. Security Group, Network ACL route table etc.)

With this in mind we can first check the instance state, subnet, InstanceProfile, and Security Group.

:::info
**Note:** _For your convenience we have added the instance ID as env variable with the variable `$NEW_NODEGROUP_2_INSTANCE_ID`._
:::

```bash
$ aws ec2 describe-instances --instance-ids $NEW_NODEGROUP_2_INSTANCE_ID --query 'Reservations[*].Instances[*].{InstanceState: State.Name, SubnetId: SubnetId, VpcId: VpcId, InstanceProfile: IamInstanceProfile, SecurityGroups: SecurityGroups}' --output json

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

:::info
Alternatively, you can also use the console for the same. Click the button below to open the EC2 Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:instanceState=running;search=troubleshooting-two-eks-workshop"
  service="ec2"
  label="Open EC2 Console"
/>
:::

### Step 4

The instance is in the running state! We are also aware that the Devops engineer created a new subnet, so we can start from the top by checking the subnet configurations and its associated route table configuration.

:::info
**Note:** _For your convenience we have added the Subnet ID as env variable with the variable `$NEW_NODEGROUP_2_SUBNET_ID`._
:::

```bash
$ aws ec2 describe-subnets --subnet-ids $NEW_NODEGROUP_2_SUBNET_ID --query 'Subnets[*].{AvailabilityZone: AvailabilityZone, AvailableIpAddressCount: AvailableIpAddressCount, CidrBlock: CidrBlock, State: State}'

[
    {
        "AvailabilityZone": "us-west-2a",
        "AvailableIpAddressCount": 8186,
        "CidrBlock": "10.42.192.0/19",
        "State": "available"
    }
]
```

There are available Ip addresses, now lets check the route table for available routes. Keep in mind worker nodes will need certain network connectivity in order to make API calls to AWS services and pull container images (EC2, ECR, STS - for IAM role for service accounts). More information [here](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html).

First we can obtain the route table ID.

```bash
$ aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$NEW_NODEGROUP_2_SUBNET_ID" \
  --query "RouteTables[*].{RouteTableId:RouteTableId,AssociatedSubnets:Associations[*].SubnetId}"

[
    {
        "RouteTableId": "rtb-1234abcd1234abcd1",
        "AssociatedSubnets": [
            "subnet-1234abcd1234abcd1"
        ]
    }
]

```

Then describe the route table for the current routes.

:::info
**Note:** _For your convenience we have added the Subnet ID as env variable with the variable `$NEW_NODEGROUP_2_ROUTETABLE_ID`._
:::

```bash timeout=15 hook=fix-2-2 hookTimeout=20
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[0].Routes'

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
Alternatively, you can also check the console for the same. Click the button below to open the VPC Console. For subnet details you can check the Details tab, and Route tables tab for route table routes.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

### Step 5

Based on the routes configured on the Route table, we can see there is only a local route (10.42.0.0/16) and no route to the internet. In order for the worker node to communicate with the required services, it will need to reach the internet. To keep the environment more secure from the internet, we can configure a NAT gateway to allow outgoing traffic only. There is already a NAT gateway which is in use for this cluster, so please go ahead and configure this to help worker nodes join the cluster.

:::info
**Note:** _For your convenience we have added the NatGateway ID as env variable with the variable `$DEFAULT_NODEGROUP_NATGATEWAY_ID`._
:::

The command below will add a route to CIDR block 0.0.0.0/0 the the existing NAT gateway.

```bash
$ aws ec2 create-route --route-table-id $NEW_NODEGROUP_2_ROUTETABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $DEFAULT_NODEGROUP_NATGATEWAY_ID

{
    "Return": true
}

```

Describe the route table to see the newly added route:

```bash
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[*].{RouteTableId:RouteTableId,VpcId:VpcId,Routes:Routes}'
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
Alternatively, you can also use the console for the same. Click the button below to open the VPC Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

### Step 6

Now that the new route has been set, we can start up a new node by decreasing the managed node group desired count to 0 and then back to 1.

The script below will modify desiredSize to 0, wait for the nodegroup status to transition from InProgress to Active, then exit. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=0; aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2; if [ $? -eq 0 ]; then echo "Node group scaled down to 0"; else echo "Failed to scale down node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "0"
            }
        ],
        "createdAt": "2024-10-23T14:33:09.671000+00:00",
        "errors": []
    }
}
Node group scaled down to 0

```

Once the above command is successful, you can set the desiredSize back to 1. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2; if [ $? -eq 0 ]; then echo "Node group scaled up to 1"; else echo "Failed to scale up node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "1"
            }
        ],
        "createdAt": "2024-10-23T14:37:41.899000+00:00",
        "errors": []
    }
}
Node group scaled up to 1
```

If all goes well, you will see the new node join on the cluster after about up to one minute.

```bash timeout=100 hook=fix-2-3 hookTimeout=110 wait=70
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

## Wrapping it up

In this section we covered an issues where network routing caused the worker node fail to join the cluster. In particular, worker nodes will not be able to join a cluster due to its requirement to reach AWS services during the bootstrapping process like EC2 (for VPC CNI activities), ECR (to pull containers), or S3 (to pull the actual image layers). By default, access to these services will be reached through a public endpoint (e.g. [EC2 public endpoint ec2.us-east-2.amazonaws.com](https://docs.aws.amazon.com/general/latest/gr/ec2-service.html#ec2_region)), but in this scenario there were no route configured to a NAT gateway on the route table, so we configured the appropriate route for the subnet.

This is one of various other networking configurations that can cause node join failures. Some other core components include:

- Security group access. If security group needs stricter restrictions, it must maintain the minimum requirementes stated [here](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#security-group-restricting-cluster-traffic) for the cluster.
- Access Control Lists (ACL) is another component that can prevent required access between the cluster and worker nodes.

Sometimes, EKS clusters may need to follow strict security requirements where the cluster can not have any inbound or outbound access to the internet. In such case, you can utilize [VPC endpoints](https://docs.aws.amazon.com/whitepapers/latest/aws-privatelink/what-are-vpc-endpoints.html) to allow private access to the required services. See the below resources for more details.

- [AWS User Guide for Private Clusters](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html)
- [Configuring Private Access to additional AWS services - eksctl guide](https://eksctl.io/usage/eks-private-cluster/#configuring-private-access-to-additional-aws-services)

For a full troubleshooting guide of joining worker nodes to the cluster, you can review the knowledge center article [here](https://repost.aws/knowledge-center/eks-worker-nodes-cluster).
