---
title: "クラスターメトリクス"
sidebar_position: 10
tmdTranslationSourceHash: 2c66fe48c70c4039dd8856f2d14ddfd6
---

EKSクラスター用のCloudWatch Container InsightsメトリクスをADOTコレクターで有効にする方法を調査します。最初に必要なことは、クラスター内にコレクターを作成して、ノード、ポッド、コンテナなどのクラスターのさまざまな側面に関するメトリクスを収集することです。

完全なコレクターマニフェストは以下で確認でき、その後で詳しく分解して説明します。

<details>
  <summary>コレクターマニフェスト全体を展開</summary>

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml"}

</details>

これをいくつかの部分に分けて理解しやすくしましょう。

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.image" zoomAfter="1"}

OpenTelemetryコレクターは、収集するテレメトリによって異なるモードで実行できます。今回はDaemonSetとして実行し、EKSクラスター内の各ノードにポッドが実行されるようにします。これにより、ノードとコンテナランタイムからテレメトリを収集できます。

次に、コレクター設定自体を分解していきます。

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.receivers.awscontainerinsightreceiver" zoomBefore="2"}

まず、[AWS Container Insights Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/9da7fea0097b991b771e0999bc4cd930edb221e2/receiver/awscontainerinsightreceiver/README.md)を設定して、ノードからメトリクスを収集します。

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.processors"}

次に、バッチプロセッサを使用して、最大60秒間バッファリングされたメトリクスをフラッシュすることでCloudWatchへのAPI呼び出し回数を減らします。

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.exporters.awsemf/performance.namespace" zoomBefore="2" zoomAfter="1"}

そして[AWS CloudWatch EMF Exporter for OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md)を使用してOpenTelemetryメトリクスを[AWS CloudWatch Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html)に変換し、[PutLogEvents](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html) APIを使用して直接CloudWatch Logsに送信します。ログエントリは表示されているCloudWatch Logsロググループに送信され、メトリクスは`ContainerInsights`名前空間に表示されます。このセクションの残りの部分は長すぎるため全体を表示できませんが、上記の完全なマニフェストを参照してください。

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.service.pipelines"}

最後に、OpenTelemetryパイプラインを使用して、レシーバー、プロセッサー、エクスポーターを組み合わせる必要があります。

マネージドIAMポリシー`CloudWatchAgentServerPolicy`を使用して、IAMロールをサービスアカウントに付与し、コレクターがメトリクスをCloudWatchに送信するために必要なIAM権限を提供します：

```bash
$ aws iam list-attached-role-policies \
  --role-name eks-workshop-adot-collector-ci | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "CloudWatchAgentServerPolicy",
      "PolicyArn": "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  ]
}
```

このIAMロールはコレクターのServiceAccountに追加されます：

```file
manifests/modules/observability/container-insights/adot/serviceaccount.yaml
```

上記で検討したリソースを作成します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/container-insights/adot \
  | envsubst | kubectl apply -f- && sleep 5
$ kubectl rollout status -n other daemonset/adot-container-ci-collector --timeout=120s
```

DaemonSetによって作成されたPodを検査して、コレクターが実行されていることを確認できます：

```bash hook=metrics
$ kubectl get pod -n other -l app.kubernetes.io/name=adot-container-ci-collector
NAME                               READY   STATUS    RESTARTS   AGE
adot-container-ci-collector-5lp5g  1/1     Running   0          15s
adot-container-ci-collector-ctvgs  1/1     Running   0          15s
adot-container-ci-collector-w4vqs  1/1     Running   0          15s
```

これはコレクターが実行されクラスターからメトリクスを収集していることを示しています。メトリクスを表示するには、まずCloudWatchコンソールを開き、Container Insightsに移動します：

:::tip
以下の点に注意してください：

1. CloudWatchにデータが表示され始めるまで数分かかることがあります
2. [拡張観測性を備えたCloudWatchエージェント](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-agent.html)によって提供される一部のメトリクスが欠落していることが予想されます

:::

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#container-insights:performance/EKS:Cluster?~(query~(controls~(CW*3a*3aEKS.cluster~(~'eks-workshop)))~context~())" service="cloudwatch" label="CloudWatchコンソールを開く"/>

![ContainerInsightsConsole](/docs/observability/container-insights/container-insights-metrics-console.webp)

コンソールを探索して、クラスター、名前空間、ポッドなど、メトリクスが表示されるさまざまな方法を確認することができます。
