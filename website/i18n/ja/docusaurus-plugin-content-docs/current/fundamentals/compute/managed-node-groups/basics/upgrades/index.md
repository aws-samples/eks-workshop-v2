---
title: AMIのアップグレード
sidebar_position: 60
kiteTranslationSourceHash: 3788124dc0896536b1da6028aa4bd63b
---

[Amazon EKS最適化Amazon Linux AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-amis.html)はAmazon Linux 2をベースに構築され、Amazon EKSノードのベースイメージとして機能するように構成されています。EKSクラスターにノードを追加する際には、最新バージョンのEKS最適化AMIを使用することがベストプラクティスとされています。新しいリリースにはKubernetesのパッチやセキュリティアップデートが含まれているためです。また、EKSクラスターにすでにプロビジョニングされている既存のノードもアップグレードすることが重要です。

EKSマネージドノードグループは、管理するノードで使用されているAMIの更新を自動化する機能を提供しています。KubernetesAPIを使用してノードを自動的にドレインし、アプリケーションの可用性を確保するために設定した[Pod disruption budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)を尊重します。

Amazon EKSマネージドワーカーノードのアップグレードには4つのフェーズがあります：

**セットアップ**:

- 最新のAMIを搭載したAuto Scaling groupに関連付けられた新しいAmazon EC2起動テンプレートバージョンを作成
- Auto Scaling groupが最新バージョンの起動テンプレートを使用するように設定
- ノードグループの`updateconfig`プロパティを使用して、並行してアップグレードするノードの最大数を決定

**スケールアップ**:

- アップグレードプロセス中、アップグレードされたノードはアップグレード対象のノードと同じアベイラビリティゾーンで起動されます
- 追加ノードをサポートするために、Auto Scaling Groupの最大サイズと目標サイズをインクリメント
- Auto Scaling Groupをスケールした後、最新の構成を使用するノードがノードグループに存在するかを確認
- 最新のラベルを持たないノードグループ内のすべてのノードに`eks.amazonaws.com/nodegroup=unschedulable:NoSchedule`テイントを適用。これにより、以前の失敗したアップデートからすでに更新されたノードがテイントされるのを防ぎます

**アップグレード**:

- ランダムにノードを選択し、そのノードからPodをドレイン
- すべてのPodが退避した後にノードをcordonし、60秒待機
- cordonされたノードに対してAuto Scaling Groupに終了リクエストを送信
- 古いバージョンのノードが存在しなくなるまで、マネージドノードグループの一部であるすべてのノードに対して同様の処理を適用

**スケールダウン**:

- スケールダウンフェーズでは、アップデート開始前の値と同じになるまで、Auto Scaling groupの最大サイズと目標サイズを1ずつデクリメントします

マネージドノードグループの更新動作について詳しく知るには、[マネージドノードグループの更新フェーズ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html)をご覧ください。

### マネージドノードグループのアップグレード

:::caution

ノードグループのアップグレードには少なくとも10分かかります。十分な時間がある場合のみ、このセクションを実行してください。

:::

あなたのために準備されたEKSクラスターは、意図的に最新のAMIを実行していないマネージドノードグループを持っています。SSMをクエリすることで、最新のAMIバージョンが何かを確認できます：

```bash
$ EKS_VERSION=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.version" --output text)
$ aws ssm get-parameter --name /aws/service/eks/optimized-ami/$EKS_VERSION/amazon-linux-2023/x86_64/standard/recommended/image_id --region $AWS_REGION --query "Parameter.Value" --output text
ami-0fcd72f3118e0dd88
```

マネージドノードグループの更新を開始すると、Amazon EKSは自動的にノードを更新し、上記の手順を完了します。Amazon EKS最適化AMIを使用している場合、Amazon EKSは最新のAMIリリースバージョンの一部として、最新のセキュリティパッチとオペレーティングシステムの更新をノードに自動的に適用します。

サンプルアプリケーションをホストするために使用されているマネージドノードグループの更新を次のように開始できます：

```bash
$ aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

`kubectl`を使用してノード上のアクティビティを監視できます：

```bash test=false
$ kubectl get nodes --watch
```

MNGが更新されるまで待つ場合は、次のコマンドを実行できます：

```bash timeout=2400
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

これが完了したら、次のステップに進むことができます。
