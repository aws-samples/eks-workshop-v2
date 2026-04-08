---
title: "Container Insights on EKS"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Container Insights を使用して Amazon Elastic Kubernetes Service のワークロードからメトリクスとログを収集、集約、要約します。"
tmdTranslationSourceHash: deebb201c602a62cd9b2f89cde17a862
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=60 hook=install
$ prepare-environment observability/container-insights
```

これにより、ラボ環境に以下の変更が適用されます：

- OpenTelemetry オペレーターをインストールします
- ADOT コレクターが CloudWatch にアクセスするための IAM ロールを作成します

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/container-insights/.workshop/terraform)で確認できます。

:::

このラボでは、[CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) を有効にして使用し、コンテナ化されたアプリケーションとマイクロサービスからメトリクスとログを収集、集約、要約する方法を見ていきます。Container Insights は Amazon Elastic Container Service（Amazon ECS）、Amazon Elastic Kubernetes Service（Amazon EKS）、および Amazon EC2 上の Kubernetes プラットフォームで利用できます。Amazon ECS のサポートには Fargate のサポートも含まれています。

メトリクスには CPU、メモリ、ディスク、ネットワークなどのリソースの使用率が含まれます。Container Insights は、コンテナの再起動失敗などの診断情報も提供し、問題を迅速に特定して解決するのに役立ちます。また、Container Insights が収集するメトリクスに CloudWatch アラームを設定することもできます。

Container Insights が収集するメトリクスは CloudWatch の自動ダッシュボードで確認できます。CloudWatch Logs Insights を使用してコンテナのパフォーマンスとログデータを分析およびトラブルシューティングできます。

運用データは、パフォーマンスログイベントとして収集されます。これらのエントリは構造化された JSON スキーマを使用し、高カーディナリティデータの大規模な取り込みと保存を可能にします。このデータから、CloudWatch はクラスター、ノード、ポッド、タスク、サービスレベルの集計メトリクスを CloudWatch メトリクスとして作成します。

[AWS Distro for OpenTelemetry コレクター](https://aws-otel.github.io/)を使用して Amazon EKS クラスターからメトリクスを収集するように Container Insights を設定します。
