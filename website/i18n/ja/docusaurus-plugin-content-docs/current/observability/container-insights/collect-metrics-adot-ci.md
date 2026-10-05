---
title: "クラスターメトリクス"
sidebar_position: 10
tmdTranslationSourceHash: e62390c5293f0ca55db1ea8900716b8f
---

[Amazon CloudWatch Observability EKS add-on](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html)を使用して、EKSクラスター用のCloudWatch Container Insightsを有効にします。このアドオンは、ノード、ポッド、コンテナなどのクラスターのさまざまな側面に関するメトリクスを収集し、CloudWatchに送信するCloudWatchエージェントをデプロイします。

内部的には、CloudWatchエージェントは[OpenTelemetry](https://opentelemetry.io/)上に構築されています。OTel Container Insightsを有効にすると、エージェントは組み込みのOpenTelemetryパイプラインを実行します：[AWS Container Insights Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/awscontainerinsightreceiver/README.md)がノードとコンテナのテレメトリを収集し、[AWS CloudWatch EMF Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md)がそれを[CloudWatch Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html)に変換してCloudWatch Logsに送信します。そこでメトリクスは`ContainerInsights`名前空間に表示されます。アドオンがこのパイプラインを管理するため、デプロイや保守するコレクターマニフェスト、Helmチャート、DaemonSetはありません。エージェントはDaemonSetとして実行されるため、クラスター内の各ノードで1つのポッドが実行されます。

### CloudWatchエージェントに権限を付与する

CloudWatchエージェントは、メトリクスとログをCloudWatchに送信するためのIAM権限が必要です。[Amazon EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)を使用して権限を付与します。これにより、Kubernetes Service AccountがIAMロールを引き受けることができます。静的な認証情報は必要ありません。

Pod Identityの前提条件である[EKS Pod Identity Agent](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)アドオンは、`prepare-environment`によって既にクラスターにインストールされています。

CloudWatchエージェントが引き受けることができるIAMロールを作成します。信頼ポリシーはEKS Pod Identityサービスプリンシパルを許可し、AWSマネージド`CloudWatchAgentServerPolicy`をアタッチします：

```bash
$ aws iam create-role \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
$ aws iam attach-role-policy \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

アドオンが`amazon-cloudwatch`名前空間に作成する`cloudwatch-agent` Service Accountにロールを関連付けます：

```bash
$ aws eks create-pod-identity-association \
  --cluster-name $EKS_CLUSTER_NAME \
  --namespace amazon-cloudwatch \
  --service-account cloudwatch-agent \
  --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$EKS_CLUSTER_NAME-cloudwatch-agent
```

### Container Insightsを有効化する

次に、OTel Container Insightsを有効にして`amazon-cloudwatch-observability`アドオンをインストールします。これは、コンソールまたはAWS CLIのどちらを使用してもインストールされる同じアドオンで、CloudWatchエージェントをデプロイして設定します：

```bash
$ aws eks create-addon \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values '{"otelContainerInsights":{"enabled":true}}'
$ aws eks wait addon-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability
```

:::note
`otelContainerInsights.enabled`設定はOTel Container Insightsをオンにします。デフォルトでは有効になっていません。
:::

アドオンは`amazon-cloudwatch`名前空間にCloudWatchエージェントをDaemonSetとしてデプロイします。エージェントポッドが実行されていることを確認します：

```bash hook=metrics
$ kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
NAME                     READY   STATUS    RESTARTS   AGE
cloudwatch-agent-4frxx   1/1     Running   0          31s
cloudwatch-agent-5rvpc   1/1     Running   0          31s
cloudwatch-agent-tptl7   1/1     Running   0          31s
```

エージェントはPod Identityを介してIAMロールを引き受けるため、すぐにメトリクスをCloudWatchに送信できます。メトリクスを表示するには、CloudWatchコンソールを開き、Container Insightsに移動します：

:::tip
CloudWatchにデータが表示され始めるまで2〜3分かかることがあります。
:::

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#container-insights:performance/EKS:Cluster?~(query~(controls~(CW*3a*3aEKS.cluster~(~'eks-workshop)))~context~())" service="cloudwatch" label="CloudWatchコンソールを開く"/>

![ContainerInsightsConsole](/docs/observability/container-insights/container-insights-metrics-console.webp)

コンソールを探索して、クラスター、名前空間、ポッドなど、メトリクスが表示されるさまざまな方法を確認することができます。
