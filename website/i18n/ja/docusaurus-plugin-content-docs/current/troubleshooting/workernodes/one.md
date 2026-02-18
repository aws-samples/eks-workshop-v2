---
title: "ワーカーノードの欠落"
sidebar_position: 71
chapter: true
tmdTranslationSourceHash: 7aa0a10141a53516bcaae8956ebf3223
---

::required-time

### 背景

株式会社XYZは、Kubernetesバージョン1.30を実行するEKSクラスターを使用して、us-west-2リージョンで新しいeコマースプラットフォームを立ち上げようとしています。セキュリティレビューの際、クラスターのセキュリティ態勢、特にノードグループのボリューム暗号化とAMIカスタマイズに関するいくつかのギャップが特定されました。

セキュリティチームは以下の具体的な要件を提示しました：

- ノードグループボリュームの暗号化の有効化
- ベストプラクティスに基づくネットワーク設定
- EKS最適化AMIの使用
- Kubernetesの監査の有効化

Kubernetes経験はあるものの、EKSに関しては新人のエンジニアSamは、これらの要件を実装するために*new_nodegroup_1*という名前の新しいマネージドノードグループを作成しました。しかし、ノードグループの作成は成功したように見えるものの、新しいノードがクラスターに参加していません。EKSクラスターのステータス、ノードグループの構成、Kubernetesイベントの初期チェックでは、明らかな問題は見つかりませんでした。

### ステップ1：ノードステータスの確認

まず、Samの観測した欠落しているノードについて確認しましょう：

```bash expectError=true timeout=60 hook=fix-1-1 hookTimeout=120
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
No resources found
```

:::note
これによりSamの観測が確認できました - 新しいノードグループ（new_nodegroup_1）からのノードは存在していません。
:::

### ステップ2：マネージドノードグループのステータス確認

マネージドノードグループはノードの作成を担当しているため、ノードグループの詳細を調べてみましょう。確認すべき重要な側面：

- ノードグループの存在
- ステータスと健全性
- 希望するサイズ

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1
```

:::info
EKSコンソールでもこの情報を確認できます：
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="EKSクラスターコンピューティングタブを開く"
/>
:::

### ステップ3：ノードグループの健全性ステータスの分析

ノードグループは最終的に「DEGRADED」（劣化）状態に移行するはずです。詳細なステータスを調べてみましょう：

:::info
ワーカーノードワークショップ環境が10分以内にデプロイされた場合、ノードグループが「ACTIVE」状態で表示される可能性があります。その場合は、以下の出力を参考にしてください。ノードグループはデプロイから10分以内に「DEGRADED」に移行するはずです。ステップ4に進んでAutoScalingグループを直接確認することもできます。
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
健全性ステータスはインスタンスの起動を妨げるKMSキーの問題を示しています。これはSamがボリューム暗号化を実装しようとした試みと一致しています。
:::

### ステップ4：Auto Scalingグループのアクティビティの調査

起動失敗を理解するためにASGのアクティビティを調べてみましょう：

#### 4.1. ノードグループのAuto Scalingグループ名の特定

以下のコマンドを実行して、ノードグループのAutoscaleグループ名をNEW_NODEGROUP_1_ASG_NAMEとして取得します。

```bash
$ NEW_NODEGROUP_1_ASG_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_1 --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
$ echo $NEW_NODEGROUP_1_ASG_NAME
```

#### 4.2. AutoScalingアクティビティの確認

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
この情報はEKSコンソールでも確認できます。「詳細」タブの下にあるAutoscalingグループ名をクリックして、Autoscalingアクティビティを表示します。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_1"
  service="eks"
  label="EKSクラスターノードグループタブを開く"
/>
:::

### ステップ5：起動テンプレートの設定を調べる

暗号化設定を確認するために起動テンプレートを確認しましょう：

#### 5.1. ASGまたはマネージドノードグループから起動テンプレートIDを見つける。この例ではASGを使用します

```bash
$ aws autoscaling describe-auto-scaling-groups \
--auto-scaling-group-names ${NEW_NODEGROUP_1_ASG_NAME} \
--query 'AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId' \
--output text
```

#### 5.2. 次に暗号化設定を確認できます

:::info
**注意：** _便宜上、起動テンプレートIDを環境変数 `$NEW_NODEGROUP_1_LT_ID` として追加しました。_
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

### ステップ6：KMSキーの設定を確認する

#### 6.1. KMSキーのステータスとアクセス許可を調べる

:::info
**注意：** _便宜上、KMSキーIDを環境変数 `$NEW_KMS_KEY_ID` として追加しました。_
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
この情報はKMSコンソールでも確認できます。キーには*new_kms_key_alias*の後に5つのランダムな文字列（例：_new_kms_key_alias_123ab_）が付いたエイリアスがあります：

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys"
  label="KMSカスタマー管理キーを開く"
/>
:::

#### 6.2. CMKのキーポリシーを確認する

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
キーポリシーにはAutoScalingサービスロールに必要な許可がありません。
:::

### ステップ7：解決策の実装

#### 7.1. 必要なKMSキーポリシーを追加する

```bash
$ NEW_POLICY=$(echo '{"Version":"2012-10-17","Id":"default","Statement":[{"Sid":"EnableIAMUserPermissions","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':root"},"Action":"kms:*","Resource":"*"},{"Sid":"AllowAutoScalingServiceRole","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":["kms:Encrypt","kms:Decrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],"Resource":"*"},{"Sid":"AllowAttachmentOfPersistentResources","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":"kms:CreateGrant","Resource":"*","Condition":{"Bool":{"kms:GrantIsForAWSResource":"true"}}}]}') && aws kms put-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default --policy "$NEW_POLICY" && aws kms get-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default | jq -r '.Policy | fromjson'
```

:::note
ポリシーは以下のようになります。

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

#### 7.2. ノードグループをスケールダウンしてからスケールアップする

```bash timeout=120 wait=90
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=0 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 && aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1
```

:::info
これには最大1分かかることがあります。
:::

### ステップ8：検証

修正が問題を解決したことを確認しましょう：

#### 8.1. ノードグループのステータスを確認する

```bash timeout=100 wait=70
$ aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name new_nodegroup_1 --query 'nodegroup.status' --output text
ACTIVE
```

#### 8.2. ノードの参加を確認する

```bash timeout=100 wait=10
$ kubectl wait --for=condition=ready nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

:::info
新しく参加したノードが表示されるまで最大約1分かかる場合があります。
:::

## 重要なポイント

### セキュリティ実装

- 暗号化を実装する際は、KMSキーポリシーを適切に設定する
- サービスロールに必要な権限があることを確認する
- デプロイ前にセキュリティ構成を検証する

### トラブルシューティングプロセス

- リソースチェーン（ノード→ノードグループ→ASG→起動テンプレート）をフォローする
- 各レベルでのヘルスステータスとエラーメッセージを確認する
- サービスロールのアクセス許可を確認する

### ベストプラクティス

- 本番環境以外でセキュリティ実装をテストする
- サービスロールに必要な権限を文書化する
- 適切なエラー処理と監視を実装する

### 追加リソース

- [EBS暗号化キーポリシー](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access)
- [EKS起動テンプレート](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html)
- [AMIの指定](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami)
- [ワーカーノード参加失敗のトラブルシューティング - AWSドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#worker-node-fail)
- [ワーカーノード参加失敗のトラブルシューティング - ナレッジセンター](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)
