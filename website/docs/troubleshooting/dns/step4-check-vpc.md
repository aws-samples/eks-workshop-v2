---
title: "Step 4 - Check VPC configuration"
sidebar_position: 30
---

When DNS traffic flows from application pods to kube-dns service and to Coredns pods, it likely traverses different nodes and different VPC subnets. We must ensure that that DNS traffic can flow between worker nodes and subnets at the VPC level.

In the VPC, there are two main components that can filter network traffic: Security Groups and Network ACLs.
We must ensure that Security Groups associated with worker nodes and Networks ACLs associated with worker node subnets allow DNS traffic to flow in and out.

:::info
Note that DNS traffic uses port 53 with protocols UDP and TCP.
:::

First, identify which Security Groups are associated with cluster worker nodes.

There is an especial Security Group defined during cluster creation: the cluster Security Group. EKS associates this Security Group with the cluster endpoint and with all Managed Nodes in the cluster to ensure communication between nodes and control plane. If no additional Security Group is associated with worker nodes by the user, the cluster Security Group is the only Security Group that is associated with Managed Nodes. Then, let’s identify and review this cluster security group.

Get the id of the cluster Security Group (the security group ID will be different in your environment):

```bash timeout=30
$ export CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
$ echo $CLUSTER_SG_ID
sg-0fcabbda9848b346e
```

Now let’s see whether worker nodes have additional security groups. For that, query all security groups associated with worker nodes:

```bash timeout=30
$ aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=eks-workshop-default-Node" --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups[*].GroupId]' \
    --output table
--------------------------
|    DescribeInstances   |
+------------------------+
|  i-0f3d2e04aa2ba924c   |
|  sg-0fcabbda9848b346e  |
|  i-048145e34d6093e3e   |
|  sg-0fcabbda9848b346e  |
|  i-0690dc536ec33c9eb   |
|  sg-0fcabbda9848b346e  |
+------------------------+
```

All worker nodes are associated only with the cluster security group: `sg-0fcabbda9848b346e` in my case. Then we only need to check this security group to know what traffic is allowed to reach worker nodes.

Next, check the rules in this security group and analyze whether DNS traffic is allowed or not:

```bash timeout=30
$ aws ec2 describe-security-group-rules \
    --filters Name=group-id,Values=$CLUSTER_SG_ID \
    --query 'SecurityGroupRules[*].{IsEgressRule:IsEgress,Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,CidrIpv4:CidrIpv4,SourceSG:ReferencedGroupInfo.GroupId}' \
    --output table
-----------------------------------------------------------------------------------------
|                              DescribeSecurityGroupRules                               |
+-----------+-----------+---------------+-----------+------------------------+----------+
| CidrIpv4  | FromPort  | IsEgressRule  | Protocol  |       SourceSG         | ToPort   |
+-----------+-----------+---------------+-----------+------------------------+----------+
|  0.0.0.0/0|  -1       |  True         |  -1       |  None                  |  -1      |
|  None     |  10250    |  False        |  tcp      |  sg-0fcabbda9848b346e  |  10250   |
|  None     |  -1       |  False        |  -1       |  sg-09eca28cacae05248  |  -1      |
|  None     |  443      |  False        |  tcp      |  sg-0fcabbda9848b346e  |  443     |
+-----------+-----------+---------------+-----------+------------------------+----------+
```

There are 3 Ingress rules and 1 Egress rule with the following details:

- Egress all protocols and ports to all IP addresses (0.0.0.0/0) - Note the value True in column IsEgressRule.
- Ingress TCP port 10250 from within this same security group (sg-0fcabbda9848b346e)
- Ingress TCP port 443 from within this same security group (sg-0fcabbda9848b346e)
- Ingress all protocols and ports from another security group (sg-09eca28cacae05248), which is not associated with worker nodes.

DNS traffic, which uses protocols UDP and TCP on port 53, is not allowed. Then, DNS requests from pods will be dropped and lookup request will time out, as we saw before in application logs.

### Root Casue

In an attempt to secure communications in the cluster VPC, users may restric traffic in the cluster security group, which is also applied to all worker nodes. It is important to ensure that DNS traffic is allowed in this Security Group. Alternatively, users may create a separate Security Group and associate it with all wroker nodes, to ensure that nodes and pods can connect with each other, inlcuding DNS traffic.

In this case, the cluster Security Group was restricted to allow only traffic on port 443 and 10250. DNS traffic is not allowed in the cluster Security Group nor in any other Security Group associated with worker nodes. Therefore, name resolution request from application time out and application connectivity fails.

### How to resolve this issue?

To fix this problem, we need to add a rule to this security group to allow DNS traffic. Moreover, EKS recommends that the cluster security group allows all traffic within the security group, to ensure that communication between managed nodes and control plane is allowed, [View Amazon EKS security group requirements for clusters](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html).

Execute the following command to allow all traffic within the cluster security group:

```bash timeout=30 wait=5
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID
```

Next, recreate all application pods:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

Last, check pod status to ensure that application pods move to Ready state:

```bash timeout=30
$ kubectl get pod -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                              READY   STATUS    RESTARTS   AGE
assets      assets-784b5f5656-fjh7t           1/1     Running   0          50s
carts       carts-5475469b7c-bwjsf            1/1     Running   0          50s
carts       carts-dynamodb-69fc586887-pmkw7   1/1     Running   0          19h
catalog     catalog-5578f9649b-pkdfz          1/1     Running   0          50s
catalog     catalog-mysql-0                   1/1     Running   0          19h
checkout    checkout-84c6769ddd-d46n2         1/1     Running   0          50s
checkout    checkout-redis-76bc7cb6f9-4g5qz   1/1     Running   0          23d
orders      orders-6d74499d87-mh2r2           1/1     Running   0          50s
orders      orders-mysql-6fbd688d4b-m7gpt     1/1     Running   0          19h
ui          ui-5f4d85f85f-xnh8q               1/1     Running   0          50s
```

For further details about Security Group requriemens in EKS, [View Amazon EKS security group requirements for clusters](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html).

:::info
In addition to Security Groups, Network Access Control Lists can also block traffic to and from EKS pods and nodes. Network ACLs is another important configuration to check when traffic is not flowing as expected. In this lab we are not covering Network ACLs. If you want to know more, check out [Control subnet traffic with network access control lists](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html).
:::

### Conclusions

Throughout the multiple sections of this lab, we investigated and root caused different issues that affect DNS resolution in EKS clusters, and performed the needed steps to fix them.
All application pods should be in Ready state as shown above.
