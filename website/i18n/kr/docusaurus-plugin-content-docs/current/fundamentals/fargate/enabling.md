---
title: Fargate 활성화
sidebar_position: 10
---
클러스터에서 Fargate에 Pod를 스케줄링하기 전에, 실행될 때 어떤 Pod가 Fargate를 사용할지 지정하는 Fargate 프로필을 최소한 하나 이상 정의해야 합니다.

관리자는 Fargate 프로필을 사용하여 어떤 Pod가 Fargate에서 실행될지 선언할 수 있습니다. 이는 프로필의 선택자를 통해 수행할 수 있습니다. 각 프로필에 최대 5개의 선택자를 추가할 수 있습니다. 각 선택자는 네임스페이스와 선택적 레이블을 포함합니다. 모든 선택자에 대해 네임스페이스를 정의해야 합니다. 레이블 필드는 여러 개의 선택적 키-값 쌍으로 구성됩니다. 선택자와 일치하는 Pod는 Fargate에서 스케줄링됩니다. Pod는 네임스페이스와 선택자에 지정된 레이블을 사용하여 매칭됩니다. 레이블 없이 네임스페이스 선택자가 정의된 경우, Amazon EKS는 해당 네임스페이스에서 실행되는 모든 Pod를 프로필을 사용하여 Fargate에 스케줄링하려고 시도합니다. 스케줄링될 Pod가 Fargate 프로필의 선택자 중 하나와 일치하면 해당 Pod는 Fargate에서 스케줄링됩니다.

Pod가 여러 Fargate 프로필과 일치하는 경우, Pod 사양에 다음 Kubernetes 레이블을 추가하여 Pod가 사용할 프로필을 지정할 수 있습니다: 

```eks.amazonaws.com/fargate-profile: my-fargate-profile```

Pod가 해당 프로필의 선택자와 일치해야 Fargate에 스케줄링될 수 있습니다. Kubernetes 어피니티/안티-어피니티 규칙은 Amazon EKS Fargate Pod에는 적용되지 않으며 필요하지 않습니다.

EKS 클러스터에 Fargate 프로필을 추가하는 것부터 시작해보겠습니다. 아래 명령은 다음과 같은 특성을 가진 `checkout-profile`이라는 Fargate 프로필을 생성합니다:

1. `checkout` 네임스페이스에서 `fargate: yes` 레이블이 있는 Pod를 대상으로 함
2. VPC의 프라이빗 서브넷에 Pod 배치
3. ECR에서 이미지를 가져오고, CloudWatch에 로그를 쓰는 등의 작업을 할 수 있도록 Fargate 인프라에 IAM 역할 적용

다음 명령은 프로필을 생성하며, 이는 몇 분 정도 소요됩니다:

```bash
$ aws eks create-fargate-profile \
    --cluster-name ${EKS_CLUSTER_NAME} \
    --pod-execution-role-arn $FARGATE_IAM_PROFILE_ARN \
    --fargate-profile-name checkout-profile \
    --selectors '[{"namespace": "checkout", "labels": {"fargate": "yes"}}]' \
    --subnets "[\"$PRIVATE_SUBNET_1\", \"$PRIVATE_SUBNET_2\", \"$PRIVATE_SUBNET_3\"]"

$ aws eks wait fargate-profile-active --cluster-name ${EKS_CLUSTER_NAME} \
    --fargate-profile-name checkout-profile
```

이제 Fargate 프로필을 검사할 수 있습니다:

```bash
$ aws eks describe-fargate-profile \
    --cluster-name $EKS_CLUSTER_NAME \
    --fargate-profile-name checkout-profile
{
    "fargateProfile": {
        "fargateProfileName": "checkout-profile",
        "fargateProfileArn": "arn:aws:eks:us-west-2:1234567890:fargateprofile/eks-workshop/checkout-profile/92c4e2e3-50cd-773c-1c32-52e4d44cd0ca",
        "clusterName": "eks-workshop",
        "createdAt": "2023-08-05T12:57:58.022000+00:00",
        "podExecutionRoleArn": "arn:aws:iam::1234567890:role/eks-workshop-fargate",
        "subnets": [
            "subnet-01c3614cdd385a93c",
            "subnet-0e392224ce426565a",
            "subnet-07f8a6fda62ec83df"
        ],
        "selectors": [
            {
                "namespace": "checkout",
                "labels": {
                    "fargate": "yes"
                }
            }
        ],
        "status": "ACTIVE",
        "tags": {}
    }
}
```