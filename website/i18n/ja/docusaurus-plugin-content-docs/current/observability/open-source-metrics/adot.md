---
title: "CloudWatch エージェントを使用したメトリクスの収集"
sidebar_position: 10
tmdTranslationSourceHash: 265d242dd1b3bd076c86f7a39c32c366
---

このラボでは、すでに作成されている Amazon Managed Service for Prometheus ワークスペースにメトリクスを保存します。コンソールで確認することができます：

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="APS コンソールを開く"/>

ワークスペースを表示するには、左側のコントロールパネルの **All Workspaces** タブをクリックします。**eks-workshop** で始まるワークスペースを選択すると、ルール管理やアラートマネージャーなどのワークスペース内のさまざまなタブを表示できます。

Amazon EKS クラスターからメトリクスを収集するために、[Amazon CloudWatch Observability EKS アドオン](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html)を使用します。このアドオンは CloudWatch エージェントをデプロイします。エージェントは埋め込まれた OpenTelemetry コレクターを実行し、そのコレクターには [Prometheus レシーバー](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md)と [Prometheus リモートライトエクスポーター](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter)が含まれているため、CloudWatch の代わりに Amazon Managed Service for Prometheus にアドオンをポイントすることができます。

:::info
ここでの CloudWatch エージェントには特別なことはありません。Prometheus レシーバー、`sigv4auth` エクステンション、Prometheus リモートライトエクスポーターで構成された OpenTelemetry 互換のコレクターであれば、Amazon Managed Service for Prometheus にメトリクスを送信できます。アドオンを使用するのは、コレクターやオペレーターを自分でデプロイして保守することなく、コレクターを実行するマネージドでサポートされた方法であるためです。
:::

### CloudWatch エージェントに権限を付与する

CloudWatch エージェントは、Amazon Managed Service for Prometheus ワークスペースにメトリクスをリモートライトするために IAM 権限が必要です。[Amazon EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) を使用して権限を付与します。これにより、Kubernetes サービスアカウントが静的な認証情報なしで IAM ロールを引き受けることができます。Pod Identity の前提条件である [EKS Pod Identity Agent](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) アドオンは、`prepare-environment` によってすでにクラスターにインストールされています。

CloudWatch エージェントが引き受けることができる IAM ロールを作成します。信頼ポリシーは EKS Pod Identity サービスプリンシパルを許可し、AMP インジェスション用の AWS マネージド `AmazonPrometheusRemoteWriteAccess` ポリシーと、エージェントのベースライン動作用の `CloudWatchAgentServerPolicy` をアタッチします：

```bash
$ aws iam create-role \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
$ aws iam attach-role-policy \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess
$ aws iam attach-role-policy \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

アドオンが `amazon-cloudwatch` 名前空間に作成する `cloudwatch-agent` サービスアカウントにロールを関連付けます：

```bash
$ aws eks create-pod-identity-association \
  --cluster-name $EKS_CLUSTER_NAME \
  --namespace amazon-cloudwatch \
  --service-account cloudwatch-agent \
  --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$EKS_CLUSTER_NAME-cloudwatch-agent
```

### AMP に書き込むようアドオンを設定する

アドオンに、クラスターから Prometheus メトリクスをスクレイプしてワークスペースにリモートライトする OpenTelemetry パイプラインを提供します：

```file
manifests/modules/observability/oss-metrics/cwagent-amp/cloudwatch-agent-amp.yaml
```

この設定にはいくつか重要な部分があります。`prometheusremotewrite/amp` エクスポーターは、AMP ワークスペースのリモートライトエンドポイントにメトリクスを送信し、`sigv4auth` エクステンションは、エージェントが Pod Identity を通じて取得する認証情報でこれらのリクエストに署名します。Prometheus の `scrape_configs` は、アノテーション付きの Pod（`kubernetes-pods`）からアプリケーションメトリクスを収集し、各ノードの `kubelet` と `cadvisor` エンドポイントからクラスターメトリクスを収集します。

パイプラインは、グローバルエージェント設定ではなく、`cloudwatch-agent-cluster-scraper` エージェント（単一レプリカの Deployment）に接続されています。アドオンは CloudWatch エージェントを各ノード上の DaemonSet としても実行します。リモートライトパイプラインをグローバルに接続すると、すべてのノードが同じシリーズをスクレイプして書き込み、AMP は重複したサンプルを拒否します。単一の cluster-scraper にスコープを設定することで、各シリーズが正確に一度だけ書き込まれることが保証されます。

この設定で `amazon-cloudwatch-observability` アドオンをインストールします。アドオンに渡す前に、`envsubst` を使用してワークスペースのエンドポイントとリージョンをファイルに置換します：

```bash hook=deploy-adot
$ envsubst '$AMP_ENDPOINT $AWS_REGION' \
  < ~/environment/eks-workshop/modules/observability/oss-metrics/cwagent-amp/cloudwatch-agent-amp.yaml \
  > /tmp/cloudwatch-agent-amp.yaml
$ aws eks create-addon \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values file:///tmp/cloudwatch-agent-amp.yaml
$ aws eks wait addon-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability
```

アドオンは CloudWatch エージェントを `amazon-cloudwatch` 名前空間にデプロイします。Pod が実行中であることを確認します：

```bash
$ kubectl get pods -n amazon-cloudwatch
NAME                                                          READY   STATUS    RESTARTS   AGE
amazon-cloudwatch-observability-controller-manager-7c9b8f7d   1/1     Running   0          80s
cloudwatch-agent-8xk2p                                        1/1     Running   0          72s
cloudwatch-agent-df9wz                                        1/1     Running   0          72s
cloudwatch-agent-cluster-scraper-6dfdc8f88-458kl              1/1     Running   0          72s
fluent-bit-2s7zn                                              1/1     Running   0          72s
fluent-bit-krl6t                                              1/1     Running   0          72s
kube-state-metrics-6cf6f8b5c7-h8m2p                           1/1     Running   0          72s
node-exporter-7k2ml                                           1/1     Running   0          72s
node-exporter-mfh2d                                           1/1     Running   0          72s
```

アドオンが管理するコンポーネントの組み合わせに注目してください：`cloudwatch-agent` DaemonSet、AMP パイプラインを実行する単一の `cloudwatch-agent-cluster-scraper` Deployment、`fluent-bit` DaemonSet、クラスターステートとノードレベルのメトリクスを公開する `kube-state-metrics` と `node-exporter` ワークロード — すべてマネージドアドオンとしてパッケージ化およびサポートされるオープンソースプロジェクトです。

