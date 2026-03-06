---
title: "노드 조인 실패"
sidebar_position: 72
chapter: true
tmdTranslationSourceHash: '20a9891970448c4c286fc5ecf6946e52'
---

::required-time

### 배경

Corporation XYZ의 전자상거래 플랫폼이 꾸준히 성장하면서, 엔지니어링 팀은 증가하는 워크로드를 처리하기 위해 EKS 클러스터를 확장하기로 결정했습니다. 팀은 us-west-2 리전에 새로운 서브넷을 생성하고 이 서브넷에 새로운 관리형 노드 그룹을 프로비저닝할 계획입니다.

숙련된 DevOps 엔지니어인 Sam이 이 확장 계획을 실행하는 임무를 맡았습니다. Sam은 us-west-2 리전에 새로운 CIDR 블록을 가진 새로운 VPC 서브넷을 생성하는 것으로 시작합니다. 목표는 새로운 관리형 노드 그룹이 기존 노드 그룹과 분리된 이 새로운 서브넷에서 애플리케이션 워크로드를 실행하도록 하는 것입니다.

새로운 서브넷을 생성한 후, Sam은 EKS 클러스터에서 새로운 관리형 노드 그룹 _*new_nodegroup_2*_를 구성하기 시작합니다. 노드 그룹 생성 과정에서 Sam은 새로운 노드가 EKS 클러스터에 표시되지 않고 클러스터에 조인되지 않는 것을 발견합니다.

### 단계 1: 노드 상태 확인

1. 먼저 노드 그룹 _new_nodegroup_2_의 새로운 노드가 클러스터에 표시되는지 확인해 보겠습니다:

```bash timeout=30 hook=fix-2-1 hookTimeout=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
No resources found
```

### 단계 2: 관리형 노드 그룹 상태 확인

EKS 관리형 노드 그룹 구성을 확인하여 상태와 설정을 검증해 보겠습니다:

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_2 --query 'nodegroup.{nodegroupName:nodegroupName,nodegroupArn:nodegroupArn,clusterName:clusterName,status:status,capacityType:capacityType,scalingConfig:scalingConfig,health:{issues:health.issues}}'
```

출력:

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
또는 콘솔에서도 동일하게 확인할 수 있습니다. 아래 버튼을 클릭하여 EKS 콘솔을 여세요.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="Open EKS Cluster Compute Tab"
/>
:::

출력에서 주요 관찰 사항:

- 노드 그룹 상태가 ACTIVE
- 원하는 용량이 1
- 보고된 상태 문제 없음
- 스케일링 구성이 올바름

### 단계 3: Auto Scaling Group 조사

ASG 활동을 확인하여 인스턴스 시작 상태를 파악해 보겠습니다:

#### 3.1. 노드 그룹의 Auto Scaling Group 이름 확인

아래 명령을 실행하여 노드 그룹 Autoscale Group 이름을 NEW_NODEGROUP_2_ASG_NAME으로 캡처합니다.

```bash
$ NEW_NODEGROUP_2_ASG_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_2 --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
$ echo $NEW_NODEGROUP_2_ASG_NAME
```

#### 4.2. AutoScaling 활동 확인

```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_2_ASG_NAME} --query 'Activities[*].{AutoScalingGroupName:AutoScalingGroupName,Description:Description,Cause:Cause,StatusCode:StatusCode}'
```

출력:

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
EKS 콘솔에서도 확인할 수 있습니다. Autoscaling group 이름을 클릭하여 ASG 콘솔을 열고 ASG 활동을 확인하세요.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_2"
  service="eks"
  label="Open EKS cluster Nodegroup Tab"
/>
:::

주요 발견 사항:

- 인스턴스 시작이 성공적으로 완료됨
- ASG가 정상 작동을 보고함
- 원하는 용량 변경이 처리됨

### 단계 4: EC2 인스턴스 구성 검사

시작된 EC2 인스턴스 구성을 검사해 보겠습니다:

:::info
**참고:** _편의를 위해 인스턴스 ID를 `$NEW_NODEGROUP_2_INSTANCE_ID` 변수로 추가했습니다._
:::

```bash
$ aws ec2 describe-instances --instance-ids $NEW_NODEGROUP_2_INSTANCE_ID --query 'Reservations[*].Instances[*].{InstanceState: State.Name, SubnetId: SubnetId, VpcId: VpcId, InstanceProfile: IamInstanceProfile, SecurityGroups: SecurityGroups}' --output json
```

출력:

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

확인해야 할 중요한 사항:

- 인스턴스 상태가 "running"
- 인스턴스 프로파일 및 IAM role 할당
- Security group 구성
  :::info
  콘솔을 사용하려면 아래 버튼을 클릭하여 EC2 콘솔을 여세요.
  <ConsoleButton
    url="https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:instanceState=running;search=troubleshooting-two-eks-workshop"
    service="ec2"
    label="Open EC2 Console"
  />
  :::

### 단계 5: 네트워크 구성 분석

서브넷 및 라우팅 구성을 확인해 보겠습니다:

:::info
**참고:** _편의를 위해 Subnet ID를 `$NEW_NODEGROUP_2_SUBNET_ID` 변수로 추가했습니다._
:::

#### 5.1. 서브넷 구성 확인

```bash
$ aws ec2 describe-subnets --subnet-ids $NEW_NODEGROUP_2_SUBNET_ID --query 'Subnets[*].{AvailabilityZone: AvailabilityZone, AvailableIpAddressCount: AvailableIpAddressCount, CidrBlock: CidrBlock, State: State}'
```

출력:

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

#### 5.2. 라우트 테이블 ID 가져오기

```bash
$ aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$NEW_NODEGROUP_2_SUBNET_ID" \
  --query "RouteTables[*].{RouteTableId:RouteTableId,AssociatedSubnets:Associations[*].SubnetId}"
```

출력:

```json {4}
[
  {
    "RouteTableId": "rtb-1234abcd1234abcd1",
    "AssociatedSubnets": ["subnet-1234abcd1234abcd1"]
  }
]
```

#### 5.3. 라우트 테이블 구성 검사

:::info
**참고:** _편의를 위해 Subnet ID를 `$NEW_NODEGROUP_2_ROUTETABLE_ID` 변수로 추가했습니다._
:::

```bash timeout=15 hook=fix-2-2 hookTimeout=20
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[0].Routes'
```

출력:

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
VPC 콘솔을 사용하려면 버튼을 클릭하세요. Subnet Details 탭과 Route tables 탭에서 라우트 테이블 라우트를 확인하세요.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

:::note
**중요한 발견**: 라우트 테이블은 로컬 라우트(10.42.0.0/16)만 표시하며 인터넷 액세스 경로가 없음
:::

### 단계 6: 솔루션 구현

근본 원인이 워커 노드의 인터넷 액세스 누락으로 식별되었습니다. 수정을 구현해 보겠습니다:

:::info
**참고:** _편의를 위해 NatGateway ID를 `$DEFAULT_NODEGROUP_NATGATEWAY_ID` 변수로 추가했습니다._
:::

#### 6.1. NAT Gateway 라우트 추가

```bash
$ aws ec2 create-route --route-table-id $NEW_NODEGROUP_2_ROUTETABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $DEFAULT_NODEGROUP_NATGATEWAY_ID
```

출력:

```json {}
{
  "Return": true
}
```

#### 6.2. 새 라우트 확인

```bash
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[*].{RouteTableId:RouteTableId,VpcId:VpcId,Routes:Routes}'
```

출력:

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
VPC 콘솔을 사용하려면 아래 버튼을 클릭하세요.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="Open VPC Console"
/>
:::

#### 6.3. 노드 그룹을 재활용하여 새 인스턴스 시작 트리거

노드 그룹을 스케일 다운한 후 스케일 업합니다. 최대 1분이 소요될 수 있습니다.

```bash timeout=120 wait=90
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=0 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 && aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2
```

### 단계 7: 검증

노드가 성공적으로 클러스터에 조인되었는지 확인합니다:

```bash timeout=100 hook=fix-2-3 hookTimeout=130 wait=90
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

:::info
새로 조인된 노드가 표시되기까지 약 1분이 걸릴 수 있습니다.
:::

### 주요 교훈

#### 네트워크 요구사항

- 워커 노드는 AWS 서비스 통신을 위해 인터넷 액세스가 필요합니다
- NAT Gateway는 안전한 아웃바운드 연결을 제공합니다
- 라우트 테이블 구성은 노드 부트스트래핑에 매우 중요합니다

#### 트러블슈팅 접근 방식

- 노드 그룹 구성 확인
- 인스턴스 상태 확인
- 네트워크 구성 분석
- 라우팅 테이블 검사

#### 모범 사례

- 적절한 네트워크 계획 구현
- NAT Gateway가 있는 프라이빗 서브넷 사용
- AWS 보안 모범 사례 준수
- 향상된 보안을 위해 VPC endpoints 고려

### 추가 리소스

#### 보안 및 액세스 제어

- [Security Group Requirements](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#security-group-restricting-cluster-traffic) - EKS 클러스터 통신에 필요한 필수 security group 규칙 및 구성
- [AWS User Guide for Private Clusters](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html) - 프라이빗 EKS 클러스터 설정 및 관리를 위한 종합 가이드
- [Configuring Private Access to AWS Services](https://eksctl.io/usage/eks-private-cluster/#configuring-private-access-to-additional-aws-services) - VPC endpoints를 사용하여 AWS 서비스에 대한 프라이빗 액세스 구성을 위한 상세 지침 - eksctl

#### 모범 사례 문서

- [EKS Networking Best Practices](https://docs.aws.amazon.com/eks/latest/best-practices/networking.html) - EKS 클러스터 설계 및 운영을 위한 AWS 권장 네트워킹 사례
- [VPC Endpoint Services Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) - 안전한 서비스 액세스를 위한 VPC endpoints 구현 및 관리에 대한 완전한 가이드

:::tip
EKS 네트워킹에 대한 포괄적인 이해를 위해 [EKS Networking Documentation](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)를 검토하세요. 트러블슈팅 가이드는 [Knowledge Center 문서](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)를 참조하세요.
:::

