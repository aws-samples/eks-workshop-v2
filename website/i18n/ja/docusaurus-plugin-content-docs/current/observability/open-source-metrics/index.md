---
title: "EKS オープンソース可観測性"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で Prometheus や Grafana のようなオープンソースの可観測性ソリューションを活用します。"
tmdTranslationSourceHash: 376b5506246ca83e0630b7fe6e4d6dc6
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss-metrics
```

これにより、ラボ環境に次の変更が適用されます：

- EKS Pod Identity Agent アドオンのインストール（EKS Pod Identity 経由で CloudWatch エージェントに権限を付与するための前提条件）
- Amazon Managed Service for Prometheus ワークスペースのプロビジョニング
- ワークスペースをデータソースとして設定した Grafana のクラスターへのインストール

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss-metrics/.workshop/terraform)で確認できます。

:::

このラボでは、[Amazon CloudWatch Observability EKS アドオン](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html)を使用してアプリケーションからメトリクスを収集し、Amazon Managed Service for Prometheus にメトリクスを保存し、Grafana で可視化します。

CloudWatch Observability アドオンは CloudWatch エージェントをデプロイします。このエージェントはオープンソースをベースに構築されており、[組み込みの OpenTelemetry コレクターを実行](https://github.com/aws/amazon-cloudwatch-agent)し、[Fluent Bit](https://fluentbit.io/)でログを送信します。Cloud Native Computing Foundation の一部である [OpenTelemetry](https://opentelemetry.io/) は、アプリケーションモニタリングのための分散トレースとメトリクスを収集するためのオープンソース API、ライブラリ、およびエージェントを提供します。コレクターには Prometheus レシーバーと Prometheus Remote Write エクスポーターがバンドルされているため、アドオンを使用してクラスターから Prometheus メトリクスをスクレイプし、Amazon Managed Service for Prometheus にリモートライトすることができます。別途コレクターをデプロイまたはメンテナンスする必要はありません。

Amazon Managed Service for Prometheus は、Cloud Native Computing Foundation（CNCF）Prometheus プロジェクトに基づく Prometheus 互換のモニタリングサービスです。Amazon Elastic Kubernetes Service、Amazon Elastic Container Service、またはセルフマネージド Kubernetes クラスターをモニタリングする場合でも、独自の Prometheus の実行とスケーリングの作業が不要になります。

:::info
CDK Observability Accelerator を使用している場合は、[ADOT コレクター](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/existing-eks-observability-accelerators/existing-eks-adotmetrics-collection-observability/)や[Nvidia DCGM を使用した GPU モニタリング](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/single-new-eks-observability-accelerators/single-new-eks-gpu-opensource-observability/)など、幅広いユースケースをカバーするオープンソース可観測性パターンのコレクションをチェックしてください。
:::

