---
title: AMIのアップグレード
sidebar_position: 60
kiteTranslationSourceHash: 3788124dc0896536b1da6028aa4bd63b
---

[Amazon EKS最適化Amazon Linux AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-amis.html)はAmazon Linux 2をベースに構築され、Amazon EKSノードのベースイメージとして機能するように設定されています。EKSクラスターにノードを追加する際には、最新バージョンのEKS最適化AMIを使用することがベストプラクティスとされています。新しいリリースにはKubernetesのパッチとセキュリティアップデートが含まれているためです。また、EKSクラスターにすでにプロビジョニングされている既存のノードをアップグレードすることも重要です。

EKSマネージドノードグループは、管理するノードで使用されているAMIの更新を自動化する機能を提供します。Kubernetes APIを使用してノードを自動的にドレインし、アプリケーションの可用性を確保するために設定した[Podディスラプションバジェット](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)を尊重します。

Amazon EKSマネージドワーカーノードのアップグレードには、以下の4つのフェーズがあります：

**セットアップ**：

- 最新のAMIを使用して、Auto Scalingグループに関連付けられた新しいAmazon EC2起動テンプレートバージョンを作成します
- Auto Scalingグループが最新バージョンの起動テンプレートを使用するように設定します
- ノードグループの`updateconfig`プロパティを使用して、並行してアップグレードするノードの最大数を決定します。

**スケールアップ**：

- アップグレードプロセス中、アップグレードされたノードはアップグレード対象のノードと同じアベイラビリティゾーンで起動されます
- 追加ノードをサポートするためにAuto Scalingグループの最大サイズと希望するサイズを増加させます
- Auto Scalingグループをスケールした後、最新の設定を使用するノードがノードグループに存在するかどうかを確認します
- 最新のラベルを持たないノードグループ内の各ノードに`eks.amazonaws.com/nodegroup=unschedulable:NoSchedule`のテイントを適用します。これにより、以前の失敗したアップデートからすでに更新されているノードがテイントされるのを防ぎます。

**アップグレード**：

- ランダムにノードを選択し、そのノードからPodをドレインします。
- すべてのPodが退避した後、ノードをコードン（隔離）し、60秒待ちます
- コードンされたノードの終了リクエストをAuto Scalingグループに送信します。
- 古いバージョンのノードが存在しなくなるまで、マネージドノードグループの一部であるすべてのノードに同じプロセスを適用します

**スケールダウン**：

- スケールダウンフェーズでは、アップデート開始前と同じ値になるまで、Auto Scalingグループの最大サイズと希望するサイズを1ずつ減らします。

マネージドノードグループの更新動作について詳しくは、[マネージドノードグループの更新フェーズ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html)をご覧ください。

### マネージドノードグループのアップグレード

:::caution

ノードグループのアップグレードには少なくとも10分かかります。十分な時間がある場合のみこのセクションを実行してください

:::

あなたのために提供されたEKSクラスターは、意図的に最新のAMIを実行していないマネージドノードグループを持っています。最新のAMIバージョンがどれかは、SSMをクエリすることで確認できます：

```bash
$ EKS_VERSION=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.version" --output text)
$ aws ssm get-parameter --name /aws/service/eks/optimized-ami/$EKS_VERSION/amazon-linux-2023/x86_64/standard/recommended/image_id --region $AWS_REGION --query "Parameter.Value" --output text
ami-0fcd72f3118e0dd88
```

マネージドノードグループの更新を開始すると、Amazon EKSが自動的にノードを更新し、上記の手順を完了します。Amazon EKS最適化AMIを使用している場合、Amazon EKSは最新のAMIリリースバージョンの一部として、最新のセキュリティパッチとオペレーティングシステムのアップデートをノードに自動的に適用します。

次のようにして、サンプルアプリケーションをホストするために使用されているマネージドノードグループの更新を開始できます：

```bash
$ aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

`kubectl`を使用してノードのアクティビティを監視できます：

```bash test=false
$ kubectl get nodes --watch
```

MNGの更新が完了するまで待つ場合は、次のコマンドを実行できます：

```bash timeout=2400
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```

これが完了したら、次のステップに進むことができます。

