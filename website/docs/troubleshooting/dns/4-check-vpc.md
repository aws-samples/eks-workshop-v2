---
title: "Checking VPC configuration"
sidebar_position: 54
---

DNS traffic between application pods, kube-dns service, and CoreDNS pods often traverses multiple nodes and VPC subnets. We need to verify that DNS traffic can flow freely at the VPC level.

:::info
Two main VPC components can filter network traffic:

- Security Groups
- Network ACLs

:::

We should verify that both worker node Security Groups and subnet Network ACLs allow DNS traffic (port 53 UDP/TCP) in both directions.

### Step 1 - Identify worker node Security Groups

Let's start by identifying the Security Groups associated with cluster worker nodes.

During cluster creation, EKS creates a cluster Security Group that's associated with both the cluster endpoint and all Managed Nodes. If no additional Security Groups are configured, this is the only Security Group controlling worker node traffic.

```bash timeout=30
$ export CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
$ echo $CLUSTER_SG_ID
sg-xxxxbbda9848bxxxx
```

Now check for any additional Security Groups on worker nodes:

```bash timeout=30
$ aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=eks-workshop-default-Node" --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups[*].GroupId]' \
    --output table
--------------------------
|    DescribeInstances   |
+------------------------+
|  i-xxxx2e04aa2baxxxx   |
|  sg-xxxxbbda9848bxxxx  |
|  i-xxxx45e34d609xxxx   |
|  sg-xxxxbbda9848bxxxx  |
|  i-xxxxdc536ec33xxxx   |
|  sg-xxxxbbda9848bxxxx  |
+------------------------+
```

We can see that worker nodes only use the cluster Security Group `sg-xxxxbbda9848bxxxx`.

### Step 2 - Check worker node Security Group rules

Let's examine worker node Security Group rules:

```bash timeout=30
$ aws ec2 describe-security-group-rules \
    --filters Name=group-id,Values=$CLUSTER_SG_ID \
    --query 'SecurityGroupRules[*].{IsEgressRule:IsEgress,Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,CidrIpv4:CidrIpv4,SourceSG:ReferencedGroupInfo.GroupId}' \
    --output table

--------------------------------------------------------------------------------------------
|                                DescribeSecurityGroupRules                                |
+--------------+-----------+---------------+-----------+------------------------+----------+
|   CidrIpv4   | FromPort  | IsEgressRule  | Protocol  |       SourceSG         | ToPort   |
+--------------+-----------+---------------+-----------+------------------------+----------+
|  None        |  -1       |  False        |  -1       |  sg-085fea48222262c24  |  -1      |
|  10.52.0.0/16|  443      |  False        |  tcp      |  None                  |  443     |
|  10.53.0.0/16|  443      |  False        |  tcp      |  None                  |  443     |
|  0.0.0.0/0   |  -1       |  True         |  -1       |  None                  |  -1      |
|  None        |  -1       |  False        |  -1       |  sg-094406793b2c02fb3  |  -1      |
|  None        |  -1       |  True         |  -1       |  sg-085fea48222262c24  |  -1      |
+--------------+-----------+---------------+-----------+------------------------+----------+

```

:::info
There are 4 Ingress rules and 2 Egress rules with the following details:

- Egress all protocols/ports to anywhere (0.0.0.0/0) - Note the value True in column IsEgressRule.
- Egress all protocols/ports to security group (sg-085fea48222262c24)
- Ingress all protocols/ports from security group (sg-085fea48222262c24)
- Ingress TCP port 443 from CIDR block 10.52.0.0/16 
- Ingress TCP port 443 from CIDR block 10.53.0.0/16
- Ingress all protocols/ports from security group (sg-094406793b2c02fb3)
  :::

Notably absent are rules allowing DNS traffic (UDP/TCP port 53), explaining our DNS resolution failures.

### Root Cause

When tightening cluster security, users might overly restrict the cluster Security Group rules. For proper cluster operation, DNS traffic must be allowed either through the cluster Security Group or through a separate Security Group attached to worker nodes.

In this case, the cluster Security Group only allows ports 443 and 10250, blocking DNS traffic and causing name resolution timeouts.

### Resolution

Following [EKS security group requirements](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html), we'll allow all traffic within the cluster Security Group:

```bash timeout=30 wait=5
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID
```

Recreate the application pods:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

Verify all pods reach Ready state:

```bash timeout=30
$ kubectl get pod -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                                 READY   STATUS    RESTARTS   AGE
carts       carts-5475469b7c-bwjsf               1/1     Running   0          50s
carts       carts-dynamodb-69fc586887-pmkw7      1/1     Running   0          19h
catalog     catalog-5578f9649b-pkdfz             1/1     Running   0          50s
catalog     catalog-mysql-0                      1/1     Running   0          19h
checkout    checkout-84c6769ddd-d46n2            1/1     Running   0          50s
checkout    checkout-redis-76bc7cb6f9-4g5qz      1/1     Running   0          23d
orders      orders-6d74499d87-mh2r2              1/1     Running   0          50s
orders      orders-postgresql-6fbd688d4b-m7gpt   1/1     Running   0          19h
ui          ui-5f4d85f85f-xnh8q                  1/1     Running   0          50s
```

:::info
For more information, see [Amazon EKS security group requirements](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html).
:::

:::info Network ACLs
While this lab focuses on Security Groups, Network ACLs can also affect traffic flow in EKS clusters. For more information about Network ACLs, see [Control subnet traffic with network access control lists](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html).
:::

### Conclusions

Throughout the multiple sections of this lab, we investigated and identified the root cause of different issues that affect DNS resolution in EKS clusters, and performed the needed steps to fix them.

In this lab, we've:

1. Identified multiple issues affecting DNS resolution in our EKS cluster
2. Followed a systematic troubleshooting approach to diagnose each issue
3. Applied the necessary fixes to restore DNS functionality
4. Verified that all application pods are now running properly

All application pods should now be in Ready state with DNS resolution working correctly.
