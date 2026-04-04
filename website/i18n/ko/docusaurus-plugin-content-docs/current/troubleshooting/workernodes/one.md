---
title: "누락된 워커 노드"
sidebar_position: 71
chapter: true
tmdTranslationSourceHash: 7aa0a10141a53516bcaae8956ebf3223
---

::required-time

### 배경

XYZ 기업은 Kubernetes 버전 1.30을 실행하는 EKS 클러스터를 사용하여 us-west-2 리전에서 새로운 전자상거래 플랫폼을 출시하고 있습니다. 보안 검토 중에 클러스터의 보안 상태에서 여러 취약점이 발견되었으며, 특히 노드 그룹 볼륨 암호화 및 AMI 사용자 지정과 관련된 부분이 문제였습니다.

보안 팀은 다음과 같은 구체적인 요구 사항을 제시했습니다:

- 노드 그룹 볼륨에 대한 암호화 활성화
- 모범 사례 네트워크 구성 설정
- EKS 최적화 AMI 사용 보장
- Kubernetes 감사 활성화

Kubernetes 경험은 있지만 EKS는 처음인 Sam 엔지니어는 이러한 요구 사항을 구현하기 위해 _new_nodegroup_1_이라는 새로운 관리형 노드 그룹을 생성했습니다. 그러나 노드 그룹 생성은 성공적으로 보이지만 새 노드가 클러스터에 조인하지 않고 있습니다. EKS 클러스터 상태, 노드 그룹 구성 및 Kubernetes 이벤트에 대한 초기 점검에서는 명확한 문제가 발견되지 않았습니다.

### 1단계: 노드 상태 확인

먼저 누락된 노드에 대한 Sam의 관찰을 확인해 보겠습니다:

```bash expectError=true timeout=60 hook=fix-1-1 hookTimeout=120
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
No resources found
```

:::note
이는 Sam의 관찰을 확인시켜 줍니다 - 새 노드그룹(new_nodegroup_1)에서 노드가 존재하지 않습니다.
:::

### 2단계: 관리형 노드 그룹 상태 확인

관리형 노드 그룹이 노드 생성을 담당하므로 노드그룹 세부 정보를 살펴보겠습니다. 확인해야 할 주요 사항:

- 노드 그룹 존재 여부
- 상태 및 헬스
- 원하는 크기

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1
```

:::info
EKS 콘솔에서도 이 정보를 확인할 수 있습니다:
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="EKS 클러스터 Compute 탭 열기"
/>
:::

### 3단계: 노드 그룹 헬스 상태 분석

노드그룹은 결국 DEGRADED 상태로 전환되어야 합니다. 세부 상태를 살펴보겠습니다:

:::info
Workernodes 워크샵 환경이 10분 이내에 배포된 경우 노드그룹이 ACTIVE 상태로 표시될 수 있습니다. 그렇다면 아래 출력을 참고용으로 확인하세요. 노드그룹은 배포 후 10분 이내에 DEGRADED로 전환되어야 합니다. 4단계로 진행하여 Auto Scaling Group을 직접 확인할 수 있습니다.
:::

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1 --query 'nodegroup.{NodegroupName:nodegroupName,Status:status,ScalingConfig:scalingConfig,AutoScalingGroups:resources.autoScalingGroups,Health:health}'


{
    "nodegroup": {
        "nodegroupName": "new_nodegroup_1", <<<---
        "nodegroupArn": "arn:aws:eks:us-west-2:1234567890:nodegroup/eks-workshop/new_nodegroup_1/abcd1234-1234-abcd-1234-1234abcd1234",
        "clusterName": "eks-workshop",
        ...
        "status": "DEGRADED",               <<<---
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 0,
            "maxSize": 1,
            "desiredSize": 1                <<<---
        },
        ...
        "resources": {
            "autoScalingGroups": [
                {
                    "name": "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234"
                }
            ]
        },
        "health": {                         <<<---
            "issues": [
                {
                    "code": "AsgInstanceLaunchFailures",
                    "message": "Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state",
                    "resourceIds": [
                        "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234"
                    ]
                }
            ]
        }
        ...
}
```

:::note
헬스 상태는 인스턴스 시작을 방해하는 KMS 키 문제를 드러냅니다. 이는 볼륨 암호화를 구현하려는 Sam의 시도와 일치합니다.
:::

### 4단계: Auto Scaling Group 활동 조사

ASG 활동을 살펴보고 시작 실패를 이해해 보겠습니다:

#### 4.1. 노드그룹의 Auto Scaling Group 이름 확인

아래 명령을 실행하여 노드그룹 Autoscale Group 이름을 NEW_NODEGROUP_1_ASG_NAME으로 캡처합니다.

```bash
$ NEW_NODEGROUP_1_ASG_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1 --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
$ echo $NEW_NODEGROUP_1_ASG_NAME
```

#### 4.2. AutoScaling 활동 확인

```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_1_ASG_NAME}

{
    "Activities": [
        {
            "ActivityId": "1234abcd-1234-abcd-1234-1234abcd1234",
            "AutoScalingGroupName": "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234",
            "Description": "Launching a new EC2 instance: i-1234abcd1234abcd1.  Status Reason: Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state",
            "Cause": "At 2024-10-04T18:06:36Z an instance was started in response to a difference between desired and actual capacity, increasing the capacity from 0 to 1.",
            ...
            "StatusCode": "Cancelled",
  --->>>    "StatusMessage": "Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state"
        },
        ...
    ]
}
```

:::info
EKS 콘솔에서도 이 정보를 확인할 수 있습니다. Details 탭 아래의 Autoscaling group 이름을 클릭하여 Autoscaling 활동을 확인하세요.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_1"
  service="eks"
  label="EKS 클러스터 Nodegroup 탭 열기"
/>
:::

### 5단계: Launch Template 구성 검토

암호화 설정을 위해 Launch Template을 확인해 보겠습니다:

#### 5.1. ASG 또는 관리형 노드그룹에서 Launch Template ID 찾기. 이 예제에서는 ASG를 사용합니다

```bash
$ aws autoscaling describe-auto-scaling-groups \
--auto-scaling-group-names ${NEW_NODEGROUP_1_ASG_NAME} \
--query 'AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId' \
--output text
```

#### 5.2. 이제 암호화 설정을 확인할 수 있습니다

:::info
**참고:** _편의를 위해 Launch Template ID를 `$NEW_NODEGROUP_1_LT_ID` 변수로 추가했습니다._
:::

```bash
$ aws ec2 describe-launch-template-versions --launch-template-id ${NEW_NODEGROUP_1_LT_ID} --query 'LaunchTemplateVersions[].{LaunchTemplateId:LaunchTemplateId,DefaultVersion:DefaultVersion,BlockDeviceMappings:LaunchTemplateData.BlockDeviceMappings}'

{
    "LaunchTemplateVersions": [
        {
            "LaunchTemplateId": "lt-1234abcd1234abcd1",
            ...
            "DefaultVersion": true,
            "LaunchTemplateData": {
            ...
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/xvda",
                        "Ebs": {
    --->>>                 "Encrypted": true,
    --->>>                 "KmsKeyId": "arn:aws:kms:us-west-2:xxxxxxxxxxxx:key/xxxxxxxxxxxx",
                            "VolumeSize": 20,
                            "VolumeType": "gp2"
                        }
                    }
                ]
```

### 6단계: KMS 키 구성 확인

#### 6.1. KMS 키 상태 및 권한 검토

:::info
**참고:** _편의를 위해 KMS Key ID를 `$NEW_KMS_KEY_ID` 변수로 추가했습니다._
:::

```bash
$ aws kms describe-key --key-id ${NEW_KMS_KEY_ID} --query 'KeyMetadata.{KeyId:KeyId,Enabled:Enabled,KeyUsage:KeyUsage,KeyState:KeyState,KeyManager:KeyManager}'

{
    "KeyId": "1234abcd-1234-abcd-1234-1234abcd1234",
    "Enabled": true,                                 <<<---
    "KeyUsage": "ENCRYPT_DECRYPT",
    "KeyState": "Enabled",                           <<<---
    "KeyManager": "CUSTOMER"
}
```

:::info
KMS 콘솔에서도 이 정보를 확인할 수 있습니다. 키는 _new_kms_key_alias_로 시작하고 5자리 무작위 문자열이 뒤따르는 별칭을 가지고 있습니다(예: _new_kms_key_alias_123ab_):

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys"
  label="KMS Customer managed keys 열기"
/>
:::

#### 6.2. CMK의 키 정책 확인

```bash
$ aws kms get-key-policy --key-id ${NEW_KMS_KEY_ID} | jq -r '.Policy | fromjson'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
```

:::info
키 정책에 AutoScaling 서비스 역할에 필요한 권한이 누락되어 있습니다.
:::

### 7단계: 솔루션 구현

#### 7.1. 필요한 KMS 키 정책 추가

```bash
$ NEW_POLICY=$(echo '{"Version":"2012-10-17","Id":"default","Statement":[{"Sid":"EnableIAMUserPermissions","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':root"},"Action":"kms:*","Resource":"*"},{"Sid":"AllowAutoScalingServiceRole","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":["kms:Encrypt","kms:Decrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],"Resource":"*"},{"Sid":"AllowAttachmentOfPersistentResources","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":"kms:CreateGrant","Resource":"*","Condition":{"Bool":{"kms:GrantIsForAWSResource":"true"}}}]}') && aws kms put-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default --policy "$NEW_POLICY" && aws kms get-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default | jq -r '.Policy | fromjson'
```

:::note
정책은 아래와 유사하게 표시됩니다.

```json
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "EnableIAMUserPermissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowAutoScalingServiceRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowAttachmentOfPersistentResources",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      },
      "Action": "kms:CreateGrant",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
```

:::

#### 7.2. 노드 그룹 축소 및 확장

```bash timeout=120 wait=90
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=0 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 && aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1
```

:::info
이 작업은 최대 1분 정도 소요될 수 있습니다.
:::

### 8단계: 검증

수정 사항이 문제를 해결했는지 확인해 보겠습니다:

#### 8.1. 노드 그룹 상태 확인

```bash timeout=100 wait=70
$ aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name new_nodegroup_1 --query 'nodegroup.status' --output text
ACTIVE
```

#### 8.2. 노드 조인 확인

```bash timeout=100 wait=10
$ kubectl wait --for=condition=ready nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

:::info
새로 조인한 노드가 표시되는 데 최대 약 1분이 소요될 수 있습니다.
:::

## 주요 사항

### 보안 구현

- 암호화를 구현할 때 KMS 키 정책을 적절히 구성
- 서비스 역할에 필요한 권한이 있는지 확인
- 배포 전에 보안 구성 검증

### 트러블슈팅 프로세스

- 리소스 체인 따라가기 (노드 → 노드 그룹 → ASG → Launch Template)
- 각 레벨에서 헬스 상태 및 오류 메시지 확인
- 서비스 역할 권한 검증

### 모범 사례

- 비프로덕션 환경에서 보안 구현 테스트
- 서비스 역할에 필요한 권한 문서화
- 적절한 오류 처리 및 모니터링 구현

### 추가 리소스

- [EBS Encryption Key Policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access)
- [EKS Launch Templates](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html)
- [AMI 지정](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami)
- [워커 노드 조인 실패 트러블슈팅 - AWS Doc](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#worker-node-fail)
- [워커 노드 조인 실패 트러블슈팅 - Knowledge Center](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)

