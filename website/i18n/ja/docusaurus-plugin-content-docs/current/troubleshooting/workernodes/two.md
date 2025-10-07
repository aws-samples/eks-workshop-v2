---
title: "Node Join Failure"
sidebar_position: 72
chapter: true
kiteTranslationSourceHash: 20a9891970448c4c286fc5ecf6946e52
---

::required-time

### 背景

企業XYZのeコマースプラットフォームは着実に成長しており、エンジニアリングチームは増加するワークロードを処理するためにEKSクラスターを拡張することを決定しました。チームはus-west-2リージョンに新しいサブネットを作成し、このサブネットの下に新しいマネージドノードグループをプロビジョニングする計画です。

経験豊富なDevOpsエンジニアであるSamは、この拡張計画の実行を任されています。Samはus-west-2リージョンに新しいCIDRブロックを持つ新しいVPCサブネットを作成することから始めます。目標は、新しいマネージドノードグループが既存のノードグループとは別に、この新しいサブネットでアプリケーションワークロードを実行することです。

新しいサブネットを作成した後、Samは EKSクラスターで新しいマネージドノードグループ _*new_nodegroup_2*_ を設定しました。ノードグループの作成プロセス中、Samは新しいノードがEKSクラスターに表示されず、クラスターに参加していないことに気付きます。

### ステップ 1: ノードステータスの確認

1. まず、ノードグループ _new_nodegroup_2_ からの新しいノードがクラスターに表示されているかどうかを確認しましょう：

```bash timeout=30 hook=fix-2-1 hookTimeout=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
No resources found
```

### ステップ 2: マネージドノードグループのステータス確認

EKSマネージドノードグループの設定を調査して、そのステータスと設定を確認しましょう：

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_2 --query 'nodegroup.{nodegroupName:nodegroupName,nodegroupArn:nodegroupArn,clusterName:clusterName,status:status,capacityType:capacityType,scalingConfig:scalingConfig,health:{issues:health.issues}}'
```

出力：

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
あるいは、コンソールで同じことを確認することもできます。下のボタンをクリックしてEKSコンソールを開きましょう。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="EKSクラスターコンピューティングタブを開く"
/>
:::

出力から重要な観察点：

- ノードグループのステータスは「ACTIVE」
- 希望する容量は1
- 健康上の問題は報告されていない
- スケーリング設定は正しい

### ステップ 3: オートスケーリンググループの調査

インスタンス起動の状態を理解するために、ASGアクティビティをチェックしましょう：

#### 3.1. ノードグループのオートスケーリンググループ名の特定

以下のコマンドを実行して、ノードグループのオートスケールグループ名をNEW_NODEGROUP_2_ASG_NAMEとして取得します。

```bash
$ NEW_NODEGROUP_2_ASG_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_2 --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
$ echo $NEW_NODEGROUP_2_ASG_NAME
```

#### 4.2. オートスケーリングアクティビティの確認

```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_2_ASG_NAME} --query 'Activities[*].{AutoScalingGroupName:AutoScalingGroupName,Description:Description,Cause:Cause,StatusCode:StatusCode}'
```

出力：

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
EKSコンソールでも確認できます。オートスケーリンググループ名をクリックしてASGコンソールビューのASGアクティビティを開きます。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_2"
  service="eks"
  label="EKSクラスターノードグループタブを開く"
/>
:::

主な発見：

- インスタンス起動は成功した
- ASGは正常な操作を報告している
- 希望する容量の変更は処理された

### ステップ 4: EC2インスタンス設定の検査

起動されたEC2インスタンスの設定を調べましょう：

:::info
**注意:** _あなたの便宜のために、インスタンスIDを環境変数 `$NEW_NODEGROUP_2_INSTANCE_ID` として追加しました。_
:::

```bash
$ aws ec2 describe-instances --instance-ids $NEW_NODEGROUP_2_INSTANCE_ID --query 'Reservations[*].Instances[*].{InstanceState: State.Name, SubnetId: SubnetId, VpcId: VpcId, InstanceProfile: IamInstanceProfile, SecurityGroups: SecurityGroups}' --output json
```

出力：

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

確認すべき重要な点：

- インスタンスの状態は「実行中」
- インスタンスプロファイルとIAMロールの割り当て
- セキュリティグループの設定
  :::info
  コンソールを使用するには、下のボタンをクリックしてEC2コンソールを開きましょう。
  <ConsoleButton
    url="https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:instanceState=running;search=troubleshooting-two-eks-workshop"
    service="ec2"
    label="EC2コンソールを開く"
  />
  :::

### ステップ 5: ネットワーク設定の分析

サブネットとルーティング設定を調べましょう：

:::info
**注意:** _あなたの便宜のために、サブネットIDを環境変数 `$NEW_NODEGROUP_2_SUBNET_ID` として追加しました。_
:::

#### 5.1. サブネット設定の確認

```bash
$ aws ec2 describe-subnets --subnet-ids $NEW_NODEGROUP_2_SUBNET_ID --query 'Subnets[*].{AvailabilityZone: AvailabilityZone, AvailableIpAddressCount: AvailableIpAddressCount, CidrBlock: CidrBlock, State: State}'
```

出力：

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

#### 5.2. ルートテーブルIDの取得

```bash
$ aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$NEW_NODEGROUP_2_SUBNET_ID" \
  --query "RouteTables[*].{RouteTableId:RouteTableId,AssociatedSubnets:Associations[*].SubnetId}"
```

出力：

```json {4}
[
  {
    "RouteTableId": "rtb-1234abcd1234abcd1",
    "AssociatedSubnets": ["subnet-1234abcd1234abcd1"]
  }
]
```

#### 5.3. ルートテーブル設定の検査

:::info
**注意:** _あなたの便宜のために、サブネットIDを環境変数 `$NEW_NODEGROUP_2_ROUTETABLE_ID` として追加しました。_
:::

```bash timeout=15 hook=fix-2-2 hookTimeout=20
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[0].Routes'
```

出力：

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
VPCコンソールを使用するには、ボタンをクリックしてください。サブネットの詳細タブとルートテーブルタブでルートテーブルルートを確認します。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="VPCコンソールを開く"
/>
:::

:::note
**重要な発見**：ルートテーブルにはローカルルート（10.42.0.0/16）のみが表示され、インターネットアクセスのパスがありません
:::

### ステップ 6: 解決策の実装

根本的な原因はワーカーノードのインターネットアクセスがないことと特定されました。修正を実装しましょう：

:::info
**注意:** _あなたの便宜のために、NATゲートウェイIDを環境変数 `$DEFAULT_NODEGROUP_NATGATEWAY_ID` として追加しました。_
:::

#### 6.1. NATゲートウェイルートの追加

```bash
$ aws ec2 create-route --route-table-id $NEW_NODEGROUP_2_ROUTETABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $DEFAULT_NODEGROUP_NATGATEWAY_ID
```

出力：

```json {}
{
  "Return": true
}
```

#### 6.2. 新しいルートの確認

```bash
$ aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[*].{RouteTableId:RouteTableId,VpcId:VpcId,Routes:Routes}'
```

出力：

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
VPCコンソールを使用するには、下のボタンをクリックしてください。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/vpcconsole/home?region=us-west-2#subnets:search=NewPrivateSubnet"
  service="vpc"
  label="VPCコンソールを開く"
/>
:::

#### 6.3. 新しいインスタンス起動をトリガーするためのノードグループのリサイクル

ノードグループをスケールダウンしてスケールアップします。これには最大1分かかる場合があります。

```bash timeout=120 wait=90
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=0 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 && aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_2
```

### ステップ 7: 検証

ノードが正常にクラスターに参加したことを確認します：

```bash timeout=100 hook=fix-2-3 hookTimeout=130 wait=90
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_2
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

:::info
新しく参加したノードが表示されるまでに最大約1分かかる場合があります。
:::

### 重要なポイント

#### ネットワーク要件

- ワーカーノードはAWSサービス通信のためのインターネットアクセスが必要
- NATゲートウェイは安全なアウトバウンド接続を提供
- ルートテーブル設定はノードブートストラッピングに不可欠

#### トラブルシューティングのアプローチ

- ノードグループ設定の確認
- インスタンスのステータスの確認
- ネットワーク設定の分析
- ルーティングテーブルの検査

#### ベストプラクティス

- 適切なネットワーク計画の実装
- NATゲートウェイを使用したプライベートサブネットの使用
- AWSセキュリティのベストプラクティスに従う
- セキュリティ強化のためのVPCエンドポイントの検討

### 追加リソース

#### セキュリティとアクセス制御

- [セキュリティグループの要件](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#security-group-restricting-cluster-traffic) - EKSクラスター通信に必要な重要なセキュリティグループのルールと設定
- [プライベートクラスターのAWSユーザーガイド](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html) - プライベートEKSクラスターの設定と管理のための包括的なガイド
- [AWSサービスへのプライベートアクセスの設定](https://eksctl.io/usage/eks-private-cluster/#configuring-private-access-to-additional-aws-services) - VPCエンドポイントを使用したAWSサービスへのプライベートアクセスを設定するための詳細な手順 - eksctl

#### ベストプラクティスのドキュメント

- [EKSネットワーキングのベストプラクティス](https://docs.aws.amazon.com/eks/latest/best-practices/networking.html) - EKSクラスターの設計と運用のためのAWS推奨ネットワーキングプラクティス
- [VPCエンドポイントサービスガイド](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) - 安全なサービスアクセスのためのVPCエンドポイントの実装と管理の完全ガイド

:::tip
EKSネットワーキングに関する総合的な理解については、[EKSネットワーキングドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)を確認してください。トラブルシューティングガイドについては、[ナレッジセンターの記事](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)を確認してください。
:::

