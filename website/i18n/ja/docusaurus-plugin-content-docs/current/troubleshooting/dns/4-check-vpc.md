---
title: "VPC設定の確認"
sidebar_position: 54
tmdTranslationSourceHash: 060991295af7b0ad6fa97095b2ec7e96
---

アプリケーションポッド、kube-dnsサービス、CoreDNSポッド間のDNSトラフィックは、多くの場合、複数のノードやVPCサブネットを通過します。VPCレベルでDNSトラフィックが自由に流れることができることを確認する必要があります。

:::info
ネットワークトラフィックをフィルタリングする2つの主なVPCコンポーネント：

- Security Groups
- Network ACL

:::

ワーカーノードのSecurity GroupsとサブネットのNetwork ACLの両方が、DNSトラフィック（ポート53 UDP/TCP）を双方向で許可していることを確認する必要があります。

### ステップ1 - ワーカーノードのSecurity Groupsを特定する

まず、クラスターワーカーノードに関連付けられているSecurity Groupsを特定しましょう。

クラスター作成時、EKSはクラスターエンドポイントと全てのManaged Nodesの両方に関連付けられるクラスターSecurity Groupを作成します。追加のSecurity Groupsが構成されていない場合、これがワーカーノードのトラフィックを制御する唯一のSecurity Groupです。

```bash timeout=30
$ export CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
$ echo $CLUSTER_SG_ID
sg-xxxxbbda9848bxxxx
```

次に、ワーカーノードに設定されている追加のSecurity Groupsがあるか確認します：

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

ワーカーノードは`sg-xxxxbbda9848bxxxx`というクラスターSecurity Groupのみを使用していることがわかります。

### ステップ2 - ワーカーノードのSecurity Groupルールを確認する

ワーカーノードのSecurity Groupルールを調べてみましょう：

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
4つのIngressルールと2つのEgressルールが存在し、以下の詳細があります：

- すべてのIPアドレス（0.0.0.0/0）へのすべてのプロトコルとポートのEgress - IsEgressRuleの列の値がTrueであることに注目してください。
- Security Group（sg-085fea48222262c24）へのすべてのプロトコルとポートのEgress
- Security Group（sg-085fea48222262c24）からのすべてのプロトコルとポートのIngress
- CIDRブロック10.52.0.0/16からのTCPポート443へのIngress
- CIDRブロック10.53.0.0/16からのTCPポート443へのIngress
- Security Group（sg-094406793b2c02fb3）からのすべてのプロトコルとポートのIngress
  :::

注目すべき点として、DNSトラフィック（UDP/TCPポート53）を許可するルールが存在せず、これがDNS解決の失敗の原因です。

### 根本原因

クラスターのセキュリティを強化する際、ユーザーがクラスターSecurity Groupのルールを過度に制限してしまうことがあります。クラスターの適切な操作のために、DNSトラフィックはクラスターSecurity Groupを通じて、またはワーカーノードに接続された別のSecurity Groupを通じて許可される必要があります。

この場合、クラスターSecurity Groupはポート443と10250のみを許可し、DNSトラフィックをブロックしているため、名前解決のタイムアウトが発生しています。

### 解決策

[EKSセキュリティグループの要件](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)に従って、クラスターSecurity Group内のすべてのトラフィックを許可します：

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

:::info Network ACL
このラボではSecurity Groupsに焦点を当てていますが、Network ACLもEKSクラスターのトラフィックフローに影響を与える可能性があります。Network ACLの詳細については、[ネットワークアクセスコントロールリストでサブネットトラフィックを制御する](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)を参照してください。
:::

### 結論

このラボの複数のセクションを通じて、EKSクラスターのDNS解決に影響するさまざまな問題の根本原因を調査・特定し、それらを修正するために必要な手順を実行しました。

このラボでは、以下のことを行いました：

1. EKSクラスターのDNS解決に影響する複数の問題を特定
2. 各問題を診断するために体系的なトラブルシューティングアプローチに従う
3. DNS機能を復元するために必要な修正を適用
4. すべてのアプリケーションポッドが適切に動作していることを確認

これですべてのアプリケーションポッドがReady状態になり、DNS解決が正しく機能するようになりました。

