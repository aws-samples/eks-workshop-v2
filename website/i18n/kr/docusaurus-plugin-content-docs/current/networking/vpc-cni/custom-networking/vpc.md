---
title: "VPC 아키텍처"
sidebar_position: 5
---

설정된 VPC를 검사하는 것부터 시작해보겠습니다. 예를 들어 VPC를 설명하면:

```bash
$ aws ec2 describe-vpcs --vpc-ids $VPC_ID
{
    "Vpcs": [
        {
            "CidrBlock": "10.42.0.0/16",
            "DhcpOptionsId": "dopt-0b9864a5c5bbe59bf",
            "State": "available",
            "VpcId": "vpc-0512db3d3af8fa5b0",
            "OwnerId": "188130284088",
            "InstanceTenancy": "default",
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-04cf2a625fa24724b",
                    "CidrBlock": "10.42.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                },
                {
                    "AssociationId": "vpc-cidr-assoc-0453603b1ab691914",
                    "CidrBlock": "100.64.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": false,
            "Tags": [
                {
                    "Key": "created-by",
                    "Value": "eks-workshop-v2"
                },
                {
                    "Key": "env",
                    "Value": "cluster"
                },
                {
                    "Key": "Name",
                    "Value": "eks-workshop-vpc"
                }
            ]
        }
    ]
}
```

여기서 VPC와 연결된 두 개의 CIDR 범위를 볼 수 있습니다:

1. "기본" CIDR인 `10.42.0.0/16` 범위
2. "보조" CIDR인 `100.64.0.0/16` 범위

AWS 콘솔에서도 이를 확인할 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#vpcs:tag:created-by=eks-workshop-v2" service="vpc" label="VPC 콘솔 열기"/>

VPC와 연결된 서브넷을 설명하면 9개의 서브넷이 표시됩니다:

```bash
$ aws ec2 describe-subnets --filters "Name=tag:created-by,Values=eks-workshop-v2" \
  --query "Subnets[*].CidrBlock"
[
    "10.42.64.0/19",
    "100.64.32.0/19",
    "100.64.0.0/19",
    "100.64.64.0/19",
    "10.42.160.0/19",
    "10.42.0.0/19",
    "10.42.96.0/19",
    "10.42.128.0/19",
    "10.42.32.0/19"
]
```

이는 다음과 같이 나뉩니다:

- 퍼블릭 서브넷: 기본 CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 하나
- 프라이빗 서브넷: 기본 CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 하나
- 보조 프라이빗 서브넷: **보조** CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 하나

![VPC 서브넷 아키텍처](./assets/vpc-secondary-networking.webp)

AWS 콘솔에서 이러한 서브넷을 볼 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#subnets:tag:created-by=eks-workshop-v2;sort=desc:CidrBlock" service="vpc" label="VPC 콘솔 열기"/>

현재 우리의 파드들은 프라이빗 서브넷 `10.42.96.0/19`, `10.42.128.0/19`, `10.42.160.0/19`를 사용하고 있습니다. 이 실습에서는 이들을 `100.64` 서브넷에서 IP 주소를 사용하도록 이동할 것입니다.