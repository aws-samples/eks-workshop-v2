---
title: "アプリケーションメトリクス"
sidebar_position: 50
tmdTranslationSourceHash: 1212a2b344ba35871f0590287ae1bb26
---

このセクションでは、ワークロードによって公開されているメトリクスの洞察を得て、Amazon CloudWatchを使用してこれらのメトリクスを可視化する方法を見ていきます。これらのメトリクスの例としては以下のようなものがあります：

- Javaヒープメトリクスやデータベース接続プールのステータスなどのシステムメトリクス
- ビジネスKPIに関連するアプリケーションメトリクス

このワークショップの各コンポーネントは、特定のプログラミング言語やフレームワークに関連するライブラリを使用してPrometheusメトリクスを提供するように計装されています。ordersサービスからのこれらのメトリクスの例を次のように見ることができます：

```bash
$ kubectl -n orders exec deployment/orders -- curl http://localhost:8080/actuator/prometheus
[...]
# HELP jdbc_connections_idle Number of established but idle connections.
# TYPE jdbc_connections_idle gauge
jdbc_connections_idle{name="reader",} 10.0
jdbc_connections_idle{name="writer",} 10.0
[...]
# HELP watch_orders_total The number of orders placed
# TYPE watch_orders_total counter
watch_orders_total{productId="510a0d7e-8e83-4193-b483-e27e09ddc34d",} 2.0
watch_orders_total{productId="808a2de1-1aaa-4c25-a9b9-6612e8f29a38",} 1.0
watch_orders_total{productId="*",} 3.0
```

このコマンドの出力は詳細ですが、このラボのために`watch_orders_total`メトリクスに焦点を当てましょう：

- `watch_orders_total` - アプリケーションメトリクス - 小売店を通じて何件の注文が行われたか

## CloudWatchエージェントによるアプリケーションメトリクスのスクレイピング

前のセクションでは、Amazon CloudWatch Observabilityアドオンがインフラストラクチャメトリクスを収集するためにCloudWatchエージェントをデプロイしました。同じエージェントは[OpenTelemetry](https://opentelemetry.io/)上に構築されており、アプリケーションによって公開されたPrometheusエンドポイントをスクレイピングし、[Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html)を使用してAmazon CloudWatchに公開することもできます。

別のコレクターをデプロイする代わりに、アプリケーションPodをスクレイピングする追加のOpenTelemetryパイプラインでアドオンの構成を拡張します。アドオンは`cloudwatch-agent-cluster-scraper`という名前の専用の単一レプリカDeploymentでクラスター全体のスクレイピングを実行します（ノードごとの`cloudwatch-agent` DaemonSetとは別です）。そのため、メトリクスは重複なく一度だけ収集されます。

以下の構成はCloudWatchエージェントにPrometheusパイプラインを追加します。この構成は`~/environment/eks-workshop/modules/observability/container-insights/cwagent-prometheus/cloudwatch-agent-prometheus.yaml`にあります：

::yaml{file="manifests/modules/observability/container-insights/cwagent-prometheus/cloudwatch-agent-prometheus.yaml"}

この構成が何をしているかを説明します：

- `prometheus/appmetrics` [Prometheusレシーバー](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md)は、`orders`名前空間内で`prometheus.io/scrape`アノテーションを持つPodを発見し、それらのメトリクスエンドポイントをスクレイピングします。
- `awsemf/appmetrics` [EMFエクスポーター](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md)は、スクレイピングされたメトリクスをEmbedded Metric Formatに変換し、CloudWatchに送信します。`metric_declarations`セクションは`watch_orders_total`メトリクスを選択し、`pod`と`productId`のディメンションを使用して`ContainerInsights/Prometheus`名前空間に公開します。
- `metrics/appmetrics`パイプラインは、レシーバー、プロセッサー、エクスポーターを結びつけます。`/appmetrics`サフィックスは、このパイプラインをアドオンが自動的に管理するパイプラインとは別に保ちます。

:::tip
`^watch_orders_total$$`の`$$`は意図的なものです。CloudWatchエージェントは構成内の環境変数を展開するため、リテラルの`$`（Prometheusの正規表現の終端アンカー）を保持するには`$$`と記述する必要があります。
:::

アドオンを更新して構成を適用し、アクティブになるまで待ちます：

```bash
$ aws eks update-addon \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values file://$HOME/environment/eks-workshop/modules/observability/container-insights/cwagent-prometheus/cloudwatch-agent-prometheus.yaml \
  --resolve-conflicts OVERWRITE
$ aws eks wait addon-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability
```

クラスタースクレイパーを再起動して、新しいスクレイプジョブを取得するようにします：

```bash
$ kubectl -n amazon-cloudwatch rollout restart deployment/cloudwatch-agent-cluster-scraper
$ kubectl -n amazon-cloudwatch rollout status deployment/cloudwatch-agent-cluster-scraper --timeout=120s
```

スクレイパーがジョブをロードしたことを確認します：

```bash test=false
$ kubectl -n amazon-cloudwatch logs -l app.kubernetes.io/name=cloudwatch-agent-cluster-scraper --tail=200 | grep retail-app-pods
... "msg":"Scrape job added","jobName":"retail-app-pods"
```

これで設定が完了しましたので、以下のスクリプトを使用して負荷ジェネレーターを実行し、ストアに注文を行い、アプリケーションメトリクスを生成します：

```bash test=false
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
  namespace: other
spec:
  containers:
  - name: artillery
    image: artilleryio/artillery:2.0.0-31
    args:
    - "run"
    - "-t"
    - "http://ui.ui.svc"
    - "/scripts/scenario.yml"
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  initContainers:
  - name: setup
    image: public.ecr.aws/aws-containers/retail-store-sample-utils:load-gen.1.2.1
    command:
    - bash
    args:
    - -c
    - "cp /artillery/* /scripts"
    volumeMounts:
    - name: scripts
      mountPath: "/scripts"
  volumes:
  - name: scripts
    emptyDir: {}
EOF
```

CloudWatchコンソールを開いて、ダッシュボードセクションに移動します：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#dashboards" service="cloudwatch" label="CloudWatchコンソールを開く"/>

ダッシュボード**Order-Service-Metrics-1**を選択して、ダッシュボード内のパネルを確認します：

![Application Metrics](/docs/observability/container-insights/dashboard-metrics.webp)

:::tip
スクレイピングされたメトリクスがCloudWatchに表示されるまでに数分かかる場合があります。
:::

「Orders by Product」パネルのタイトルにカーソルを合わせて「Edit」ボタンをクリックすることで、ダッシュボードがCloudWatchをクエリするように構成されている方法を確認できます：

![Edit Panel](/docs/observability/container-insights/dashboard-edit-metrics.webp)

このパネルを作成するために使用されたクエリはページの下部に表示されます：

```text
SELECT COUNT(watch_orders_total) FROM "ContainerInsights/Prometheus" WHERE productId != '*' GROUP BY productId
```

このクエリは以下のことを行っています：

- `watch_orders_total`メトリクスをクエリする
- `productId`の値が`*`のメトリクスを無視する
- これらのメトリクスを合計し、`productId`でグループ化する

メトリクスの観察に満足したら、以下のコマンドを使用して負荷ジェネレーターを停止できます。

```bash timeout=180 test=false
$ kubectl delete pod load-generator -n other
```
