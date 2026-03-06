---
title: "VPC 구성 확인"
sidebar_position: 54
tmdTranslationSourceHash: '060991295af7b0ad6fa97095b2ec7e96'
---

애플리케이션 Pod, kube-dns 서비스, CoreDNS Pod 간의 DNS 트래픽은 종종 여러 노드와 VPC 서브넷을 통과합니다. VPC 레벨에서 DNS 트래픽이 자유롭게 흐를 수 있는지 확인해야 합니다.

:::info
네트워크 트래픽을 필터링할 수 있는 두 가지 주요 VPC 구성 요소가 있습니다:

- Security Groups
- Network ACLs

:::

워커 노드 Security Groups와 서브넷 Network ACLs 모두 양방향으로 DNS 트래픽(포트 53 UDP/TCP)을 허용하는지 확인해야 합니다.

### 1단계 - 워커 노드 Security Groups 확인

먼저 클러스터 워커 노드와 연결된 Security Groups를 확인하겠습니다.

클러스터 생성 중에 EKS는 클러스터 엔드포인트와 모든 Managed Nodes에 연결되는 클러스터 Security Group을 생성합니다. 추가 Security Groups가 구성되지 않은 경우, 이것이 워커 노드 트래픽을 제어하는 유일한 Security Group입니다.

```bash timeout=30
$ export CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
$ echo $CLUSTER_SG_ID
sg-xxxxbbda9848bxxxx
```

이제 워커 노드에 추가 Security Groups가 있는지 확인합니다:

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

워커 노드가 클러스터 Security Group `sg-xxxxbbda9848bxxxx`만 사용하는 것을 확인할 수 있습니다.

### 2단계 - 워커 노드 Security Group 규칙 확인

워커 노드 Security Group 규칙을 확인해 보겠습니다:

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
다음과 같은 세부 정보를 가진 4개의 Ingress 규칙과 2개의 Egress 규칙이 있습니다:

- Egress 모든 프로토콜/포트를 anywhere (0.0.0.0/0)로 - IsEgressRule 열의 True 값을 확인하세요.
- Egress 모든 프로토콜/포트를 security group (sg-085fea48222262c24)으로
- Ingress 모든 프로토콜/포트를 security group (sg-085fea48222262c24)에서
- Ingress TCP 포트 443을 CIDR 블록 10.52.0.0/16에서
- Ingress TCP 포트 443을 CIDR 블록 10.53.0.0/16에서
- Ingress 모든 프로토콜/포트를 security group (sg-094406793b2c02fb3)에서
  :::

주목할 만한 것은 DNS 트래픽(UDP/TCP 포트 53)을 허용하는 규칙이 없다는 것이며, 이것이 DNS 해석 실패를 설명합니다.

### 근본 원인

클러스터 보안을 강화할 때, 사용자가 클러스터 Security Group 규칙을 지나치게 제한할 수 있습니다. 적절한 클러스터 작동을 위해서는 클러스터 Security Group을 통해 또는 워커 노드에 연결된 별도의 Security Group을 통해 DNS 트래픽이 허용되어야 합니다.

이 경우 클러스터 Security Group이 포트 443과 10250만 허용하여 DNS 트래픽을 차단하고 이름 해석 시간 초과를 유발합니다.

### 해결 방법

[EKS security group 요구사항](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)에 따라 클러스터 Security Group 내의 모든 트래픽을 허용하겠습니다:

```bash timeout=30 wait=5
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID
```

애플리케이션 Pod를 재생성합니다:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

모든 Pod가 Ready 상태에 도달하는지 확인합니다:

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
자세한 내용은 [Amazon EKS security group 요구사항](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)을 참조하세요.
:::

:::info Network ACLs
이 실습은 Security Groups에 중점을 두고 있지만, Network ACLs도 EKS 클러스터의 트래픽 흐름에 영향을 줄 수 있습니다. Network ACLs에 대한 자세한 내용은 [Control subnet traffic with network access control lists](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)를 참조하세요.
:::

### 결론

이 실습의 여러 섹션에 걸쳐 EKS 클러스터에서 DNS 해석에 영향을 미치는 여러 문제의 근본 원인을 조사하고 식별했으며, 이를 수정하기 위한 필요한 단계를 수행했습니다.

이 실습에서 다음을 수행했습니다:

1. EKS 클러스터에서 DNS 해석에 영향을 미치는 여러 문제 식별
2. 각 문제를 진단하기 위한 체계적인 트러블슈팅 접근 방식 수행
3. DNS 기능을 복원하기 위한 필요한 수정 사항 적용
4. 모든 애플리케이션 Pod가 정상적으로 실행되는지 확인

이제 모든 애플리케이션 Pod가 Ready 상태이며 DNS 해석이 올바르게 작동합니다.

