---
title: "アプリケーションメトリクス"
sidebar_position: 50
kiteTranslationSourceHash: 934ca84689ea0251dc4a747720a25fc7
---

import dashboard from './assets/cw-dashboard.webp';

このセクションでは、ワークロードによって公開されているメトリクスの洞察を得て、Amazon CloudWatch Insights Prometheusを使用してこれらのメトリクスを可視化する方法を見ていきます。これらのメトリクスの例としては以下のようなものがあります：

- Javaヒープメトリクスやデータベース接続プールのステータスなどのシステムメトリクス
- ビジネスKPIに関連するアプリケーションメトリクス

AWS Distro for OpenTelemetryを使用してアプリケーションメトリクスを取り込み、Amazon CloudWatchを使用してメトリクスを可視化する方法を見てみましょう。

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
watch_orders_total{productId="6d62d909-f957-430e-8689-b5129c0bb75e",} 1.0
```

このコマンドの出力は詳細ですが、このラボのためにwatch_orders_totalメトリクスに焦点を当てましょう：

- `watch_orders_total` - アプリケーションメトリクス - 小売店を通じて何件の注文が行われたか

同様のリクエストを他のコンポーネント、例えばcheckoutサービスに実行できます：

```bash
$ kubectl -n checkout exec deployment/checkout -- curl http://localhost:8080/metrics
[...]
# HELP nodejs_heap_size_total_bytes Process heap size from Node.js in bytes.
# TYPE nodejs_heap_size_total_bytes gauge
nodejs_heap_size_total_bytes 48668672
[...]
```

すでに展開したコレクターはDaemonSetであり、すべてのノードで実行されていることを思い出してください。クラスター内のPodからメトリクスをスクレイピングする場合、これは重複したメトリクスが発生するため望ましくありません。今回は、単一のレプリカを持つDeploymentとして実行される2番目のコレクターを展開します。

<details>
  <summary>完全なコレクターマニフェストを展開</summary>

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml"}

</details>

これをいくつかの部分に分けて確認することで、より理解しやすくなります。

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml" zoomPath="spec.image" zoomAfter="1"}

前述の通り、今回はDeploymentを使用しています。

次にコレクター構成自体の内容を見ていきましょう。

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml" zoomPath="spec.config.receivers.prometheus" zoomBefore="2"}

AWS Container Insights Receiverではなく、[Prometheusレシーバー](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md)を使用してEKSクラスター内のすべてのポッドをスクレイプします。

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml" zoomPath="spec.config.processors"}

前回のコレクターと同じバッチプロセッサーを使用します。

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml" zoomPath="spec.config.exporters.awsemf/prometheus"}

AWS CloudWatch EMF Exporter for OpenTelemetry Collectorを使用しますが、今回は`ContainerInsights/Prometheus`という名前空間を使用します。

::yaml{file="manifests/modules/observability/container-insights/adot-deployment/opentelemetrycollector.yaml" zoomPath="spec.config.service.pipelines"}

前回と同様に、これらをパイプラインにまとめます。

上記で確認したリソースを作成します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/container-insights/adot-deployment \
  | envsubst | kubectl apply -f- && sleep 5
$ kubectl rollout status -n other deployment/adot-container-ci-deploy-collector --timeout=120s
```

コレクターが実行されていることを、DaemonSetによって作成されたPodを調査することで確認できます：

```bash
$ kubectl get pod -n other -l app.kubernetes.io/name=adot-container-ci-deploy-collector
NAME                                      READY   STATUS    RESTARTS   AGE
adot-container-ci-deploy-collector-5lp5g  1/1     Running   0          15s
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

ダッシュボード**Order-Service-Metrics**を選択して、ダッシュボード内のパネルを確認します：

![アプリケーションメトリクス](./assets/dashboard-metrics.webp)

「Orders by Product」パネルのタイトルにカーソルを合わせ、「編集」ボタンをクリックすることで、このダッシュボードがCloudWatchでどのようにクエリを行うように構成されているかを確認できます：

![パネル編集](./assets/dashboard-edit-metrics.webp)

このパネルを作成するために使用されたクエリはページの下部に表示されています：

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
