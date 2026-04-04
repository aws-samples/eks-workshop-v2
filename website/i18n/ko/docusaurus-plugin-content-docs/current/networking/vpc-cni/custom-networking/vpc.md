---
title: "VPC 아키텍처"
sidebar_position: 5
tmdTranslationSourceHash: '1a409175355dbb7f49a653cd96fc2366'
---

먼저 설정된 VPC를 확인해 보겠습니다. 예를 들어 VPC를 설명해 보겠습니다:

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

여기서 VPC에 두 개의 CIDR 범위가 연결되어 있음을 확인할 수 있습니다:

1. "primary" CIDR인 `10.42.0.0/16` 범위
2. "secondary" CIDR인 `100.64.0.0/16` 범위

AWS 콘솔에서도 이를 확인할 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#vpcs:tag:created-by=eks-workshop-v2" service="vpc" label="Open VPC console"/>

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

이들은 다음과 같이 구분됩니다:

- 퍼블릭 서브넷: primary CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 1개
- 프라이빗 서브넷: primary CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 1개
- 보조 프라이빗 서브넷: **secondary** CIDR 범위의 CIDR 블록을 사용하는 각 가용 영역별 1개

![VPC 서브넷 아키텍처](/docs/networking/vpc-cni/custom-networking/vpc-secondary-networking.webp)

AWS 콘솔에서 이러한 서브넷을 확인할 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#subnets:tag:created-by=eks-workshop-v2;sort=desc:CidrBlock" service="vpc" label="Open VPC console"/>

현재 Pod들은 프라이빗 서브넷 `10.42.96.0/19`, `10.42.128.0/19`, `10.42.160.0/19`를 활용하고 있습니다. 이 실습에서는 Pod들이 `100.64` 서브넷의 IP 주소를 사용하도록 변경하겠습니다.

