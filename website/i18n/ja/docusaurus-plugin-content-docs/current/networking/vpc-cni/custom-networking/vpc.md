---
title: "VPC architecture"
sidebar_position: 5
kiteTranslationSourceHash: 17b7519b5d616b5da983bb97d4df1450
---

セットアップされたVPCを調査することから始めましょう。例えば、VPCについて詳しく見てみましょう：

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

ここでVPCに関連付けられた2つのCIDRレンジがあることがわかります：

1. 「プライマリ」CIDRである`10.42.0.0/16`レンジ
2. 「セカンダリ」CIDRである`100.64.0.0/16`レンジ

AWSコンソールでも確認できます：

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#vpcs:tag:created-by=eks-workshop-v2" service="vpc" label="Open VPC console"/>

VPCに関連付けられたサブネットを記述すると、9つのサブネットが表示されます：

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

これらは以下のように分けられています：

- パブリックサブネット：プライマリCIDR範囲からのCIDRブロックを使用する各アベイラビリティゾーンに1つずつ
- プライベートサブネット：プライマリCIDR範囲からのCIDRブロックを使用する各アベイラビリティゾーンに1つずつ
- セカンダリプライベートサブネット：**セカンダリ**CIDR範囲からのCIDRブロックを使用する各アベイラビリティゾーンに1つずつ

![VPC subnet architecture](./assets/vpc-secondary-networking.webp)

これらのサブネットはAWSコンソールで確認できます：

<ConsoleButton url="https://console.aws.amazon.com/vpc/home#subnets:tag:created-by=eks-workshop-v2;sort=desc:CidrBlock" service="vpc" label="Open VPC console"/>

現在、ポッドはプライベートサブネット`10.42.96.0/19`、`10.42.128.0/19`、`10.42.160.0/19`を利用しています。この実習では、それらを`100.64`サブネットからIPアドレスを消費するように移行します。
