---
title: "VPC設定の確認"
sidebar_position: 54
kiteTranslationSourceHash: 5f4c4f4a7ac5696ae2dc32d68169e2e8
---

アプリケーションポッド、kube-dnsサービス、CoreDNSポッド間のDNSトラフィックは、多くの場合、複数のノードやVPCサブネットを通過します。VPCレベルでDNSトラフィックが自由に流れることができることを確認する必要があります。

:::info
ネットワークトラフィックをフィルタリングする2つの主なVPCコンポーネント：

- セキュリティグループ
- ネットワークACL

:::

ワーカーノードのセキュリティグループとサブネットのネットワークACLの両方が、DNSトラフィック（ポート53 UDP/TCP）を双方向で許可していることを確認する必要があります。

### ステップ1 - ワーカーノードのセキュリティグループを特定する

まず、クラスターワーカーノードに関連付けられているセキュリティグループを特定しましょう。

クラスター作成時、EKSはクラスターエンドポイントと全てのマネージドノードの両方に関連付けられるクラスターセキュリティグループを作成します。追加のセキュリティグループが構成されていない場合、これがワーカーノードのトラフィックを制御する唯一のセキュリティグループです。

```bash timeout=30
$ export CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
$ echo $CLUSTER_SG_ID
sg-xxxxbbda9848bxxxx
```

次に、ワーカーノードに設定されている追加のセキュリティグループがあるか確認します：

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

ワーカーノードは`sg-xxxxbbda9848bxxxx`というクラスターセキュリティグループのみを使用していることがわかります。

### ステップ2 - ワーカーノードのセキュリティグループルールを確認する

ワーカーノードのセキュリティグループルールを調べてみましょう：

```bash timeout=30
$ aws ec2 describe-security-group-rules \
    --filters Name=group-id,Values=$CLUSTER_SG_ID \
    --query 'SecurityGroupRules[*].{IsEgressRule:IsEgress,Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,CidrIpv4:CidrIpv4,SourceSG:ReferencedGroupInfo.GroupId}' \
    --output table
-----------------------------------------------------------------------------------------
|                              DescribeSecurityGroupRules                               |
+-----------+-----------+---------------+-----------+------------------------+----------+
| CidrIpv4  | FromPort  | IsEgressRule  | Protocol  |       SourceSG         | ToPort   |
+-----------+-----------+---------------+-----------+------------------------+----------+
|  0.0.0.0/0|  -1       |  True         |  -1       |  None                  |  -1      |
|  None     |  10250    |  False        |  tcp      |  sg-0fcabbda9848b346e  |  10250   |
|  None     |  -1       |  False        |  -1       |  sg-09eca28cacae05248  |  -1      |
|  None     |  443      |  False        |  tcp      |  sg-0fcabbda9848b346e  |  443     |
+-----------+-----------+---------------+-----------+------------------------+----------+
```

:::info
3つのインバウンドルールと1つのアウトバウンドルールが存在します：

- すべてのIPアドレス（0.0.0.0/0）へのすべてのプロトコルとポートのアウトバウンド - IsEgressRuleの列の値がTrueであることに注目してください。
- このセキュリティグループ内（sg-0fcabbda9848b346e）からのTCPポート10250へのインバウンド
- このセキュリティグループ内（sg-0fcabbda9848b346e）からのTCPポート443へのインバウンド
- ワーカーノードに関連付けられていない別のセキュリティグループ（sg-09eca28cacae05248）からのすべてのプロトコルとポートへのインバウンド

:::

注目すべき点として、DNSトラフィック（UDP/TCPポート53）を許可するルールが存在せず、これがDNS解決の失敗の原因です。

### 根本原因

クラスターのセキュリティを強化する際、ユーザーがクラスターセキュリティグループのルールを過度に制限してしまうことがあります。クラスターの適切な操作のために、DNSトラフィックはクラスターセキュリティグループを通じて、またはワーカーノードに接続された別のセキュリティグループを通じて許可される必要があります。

この場合、クラスターセキュリティグループはポート443と10250のみを許可し、DNSトラフィックをブロックしているため、名前解決のタイムアウトが発生しています。

### 解決策

[EKSセキュリティグループの要件](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)に従って、クラスターセキュリティグループ内のすべてのトラフィックを許可します：

```bash timeout=30 wait=5
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID
```

アプリケーションポッドを再作成します：

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

すべてのポッドがReady状態に達していることを確認します：

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
詳細については、[Amazon EKSセキュリティグループの要件](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)を参照してください。
:::

:::info ネットワークACL
このラボではセキュリティグループに焦点を当てていますが、ネットワークACLもEKSクラスターのトラフィックフローに影響を与える可能性があります。ネットワークACLの詳細については、[ネットワークアクセスコントロールリストでサブネットトラフィックを制御する](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)を参照してください。
:::

### 結論

このラボの複数のセクションを通じて、EKSクラスターのDNS解決に影響するさまざまな問題の根本原因を調査・特定し、それらを修正するために必要な手順を実行しました。

このラボでは、以下のことを行いました：

1. EKSクラスターのDNS解決に影響する複数の問題を特定
2. 各問題を診断するために体系的なトラブルシューティングアプローチをとる
3. DNS機能を復元するために必要な修正を適用
4. すべてのアプリケーションポッドが適切に動作していることを確認

これですべてのアプリケーションポッドがReady状態になり、DNS解決が正しく機能するようになりました。

