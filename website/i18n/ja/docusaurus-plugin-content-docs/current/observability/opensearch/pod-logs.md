---
title: "Podログ記録"
sidebar_position: 30
tmdTranslationSourceHash: 46344f2c19983ecbad56db9c77b46649
---

このセクションでは、Podログをどのように OpenSearch にエクスポートするかを示します。[AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) をデプロイしてPodログを OpenSearch にエクスポートし、ログエントリを生成して OpenSearch Pod ログダッシュボードを探索します。

次の4つの段落は、Kubernetes におけるPodログ記録と Fluent Bit の使用に関する概要を説明しています。すでに [EKSでのPodログ記録](https://www.eksworkshop.com/docs/observability/logging/pod-logging/) に関する前のセクションを読んだ方は、この概要をスキップしても構いません。

[Twelve-Factor App マニフェスト](https://12factor.net/) によれば、最新のアプリケーション設計のゴールドスタンダードを提供するもので、コンテナ化されたアプリケーションは[ログを stdout と stderr に出力する](https://12factor.net/logs)べきとされています。これは Kubernetes におけるベストプラクティスとも考えられており、クラスターレベルのログ収集システムはこの前提に基づいて構築されています。

Kubernetesのロギングアーキテクチャは3つの異なるレベルを定義しています：

- 基本レベルのロギング：kubectl を使用して Pod のログを取得する機能（例：`kubectl logs myapp` – ここで `myapp` はクラスタで実行中のポッドです）
- ノードレベルのロギング：コンテナエンジンがアプリケーションの `stdout` と `stderr` からログをキャプチャし、ログファイルに書き込みます。
- クラスターレベルのロギング：ノードレベルのロギングに基づいて構築されます。ログキャプチャエージェントが各ノードで実行されます。このエージェントはローカルファイルシステムからログを収集し、OpenSearchのような集中型ログ記録先に送信します。このエージェントは2種類のログを収集します：
  - ノード上のコンテナエンジンによってキャプチャされたコンテナログ
  - システムログ

Kubernetes 自体は、ログを収集して保存するためのネイティブなソリューションを提供していません。ローカルファイルシステムにJSONフォーマットでログを保存するようにコンテナランタイムを設定しています。Dockerのようなコンテナランタイムはコンテナの stdout と stderr ストリームをロギングドライバにリダイレクトします。Kubernetes では、コンテナログはノード上の `/var/log/pods/*.log` に書き込まれます。Kubelet とコンテナランタイムは独自のログを `/var/logs` またはsystemdを使用しているオペレーティングシステムでは journald に書き込みます。その後、Fluentd のようなクラスター全体のログコレクターシステムがノード上のこれらのログファイルを取得し、保持のためにログを送信できます。これらのログコレクターシステムは通常、ワーカーノード上で DaemonSets として実行されます。

[Fluent Bit](https://fluentbit.io/) は軽量のログプロセッサーおよびフォワーダーであり、さまざまなソースからデータとログを収集し、フィルターでエンリッチメントを行い、CloudWatch、Kinesis Data Firehose、Kinesis Data Streams、Amazon OpenSearch Service などの複数の宛先に送信することができます。

以下の図は、このセクションのセットアップの概要を示しています。Fluent Bit は `opensearch-exporter` ネームスペースにデプロイされ、Pod ログを OpenSearch ドメインに転送するように設定されます。Pod ログは OpenSearch の `eks-pod-logs` インデックスに保存されます。以前に読み込んだ OpenSearch ダッシュボードを使用して Pod ログを検査します。

![Pod logs to OpenSearch](/docs/observability/opensearch/eks-pod-logs-overview.webp)

Fluent Bit を [Daemon Set](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) としてデプロイし、OpenSearch ドメインにPodログを送信するように設定します。基本的な設定は [こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/config/fluentbit-values.yaml) で入手できます。以前に取得した OpenSearch の認証情報を使用して Fluent Bit を設定します。最後のコマンドは、Fluent Bit が3つのクラスタノードのそれぞれに1つの Pod で実行されていることを確認します。

```bash wait=60
$ helm repo add eks https://aws.github.io/eks-charts
"eks" has been added to your repositories

$ helm upgrade fluentbit eks/aws-for-fluent-bit --install \
    --namespace opensearch-exporter --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/config/fluentbit-values.yaml \
    --set="opensearch.host"="$OPENSEARCH_HOST" \
    --set="opensearch.awsRegion"=$AWS_REGION \
    --set="opensearch.httpUser"="$OPENSEARCH_USER" \
    --set="opensearch.httpPasswd"="$OPENSEARCH_PASSWORD" \
    --wait

$ kubectl get daemonset -n opensearch-exporter

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
fluentbit-aws-for-fluent-bit   3         3         3       3            3           <none>          60s

```

まず、ui コンポーネントのポッドをリサイクルして、Fluent Bit を有効にしてから新しいログが書き込まれるようにします：

```bash
$ kubectl delete pod -n ui --all
$ kubectl rollout status deployment/ui -n ui --timeout 30s
deployment "ui" successfully rolled out
```

次に、`kubectl logs` を直接使用して、`ui` コンポーネントがログを作成していることを確認できます。ログのタイムスタンプは現在の時刻（UTC形式で表示）と一致するはずです。

```bash
$ kubectl logs -n ui deployment/ui
Picked up JAVA_TOOL_OPTIONS:

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.4.4)

2025-07-26T10:38:05.763Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 21.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2025-07-26T10:38:05.820Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : The following 1 profile is active: "prod"
2025-07-26T10:38:09.105Z  INFO 1 --- [           main] i.o.i.s.a.OpenTelemetryAutoConfiguration : OpenTelemetry Spring Boot starter has been disabled

2025-07-26T10:38:10.323Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 4 endpoints beneath base path '/actuator'
2025-07-26T10:38:12.338Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080 (http)
2025-07-26T10:38:12.365Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 7.481 seconds (process running for 9.223)

```

同じログエントリが OpenSearch でも確認できます。以前に表示したダッシュボードのランディングページから Pod ログダッシュボードにアクセスするか、以下のコマンドを使用してその座標を取得します：

```bash
$ printf "\nPod logs dashboard: https://%s/_dashboards/app/dashboards#/view/31a8bd40-790a-11ee-8b75-b9bb31eee1c2 \
        \nUserName: %q \nPassword: %q \n\n" \
        "$OPENSEARCH_HOST" "$OPENSEARCH_USER" "$OPENSEARCH_PASSWORD"

Pod logs dashboard: <OpenSearch Dashboard URL>
Username: <user name>
Password: <password>
```

ダッシュボードのセクションとフィールドについての説明は以下の通りです：

1. [ヘッダー] 日付/時間範囲を表示。このダッシュボードで探索する時間範囲をカスタマイズできます（この例では過去15分）
2. [上部セクション] `stdout` と `stderr` ストリーム間の分割を示すログメッセージの日付ヒストグラム（すべてのネームスペースを含む）
3. [中央セクション] すべてのクラスターネームスペース間の分割を示すログメッセージの日付ヒストグラム
4. [下部セクション] 最新のメッセージが最初に表示されるデータテーブル。ストリーム名（`stdout` と `stderr`）は、Pod 名などの詳細と共に表示されます。デモンストレーションのため、このセクションはフィルタリングされて `ui` ネームスペースからのログのみを表示しています
5. [下部セクション] 個々のポッドから収集されたログメッセージ。この例では、表示されている最新のログメッセージは `2023-11-07T02:05:10.616Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 5.917 seconds (process running for 7.541)` であり、これは前のステップで `kubectl logs -n ui deployment/ui` を実行した際の出力の最後の行と一致します

![Pod logging dashboard](/docs/observability/opensearch/pod-logging-dashboard.webp)

ログエントリをドリルダウンして完全なJSON ペイロードを確認できます：

1. 各イベントの隣にある '>' をクリックすると新しいセクションが開きます
2. 完全なイベントドキュメントは、テーブルまたはJSON形式で表示できます
3. `log` 属性には、ポッドによって生成されたログメッセージが含まれています
4. Pod名、ネームスペース、Podラベルを含むログメッセージに関するメタデータが含まれています

![Pod logging detail](/docs/observability/opensearch/pod-logging-detail.webp)
