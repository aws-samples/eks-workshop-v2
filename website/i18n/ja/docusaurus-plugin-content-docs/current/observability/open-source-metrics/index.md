---
title: "EKS オープンソース可観測性"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で Prometheus や Grafana のようなオープンソースの可観測性ソリューションを活用します。"
kiteTranslationSourceHash: a6f25e31488b01fd4aa341767fd59b0f
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss-metrics
```

これにより、ラボ環境に次の変更が適用されます：

- OpenTelemetry オペレーターのインストール
- ADOT コレクターが Amazon Managed Prometheus にアクセスするための IAM ロールの作成

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss-metrics/.workshop/terraform)で確認できます。

:::

このラボでは、[AWS Distro for OpenTelemetry](https://aws-otel.github.io/)を使用してアプリケーションからメトリクスを収集し、Amazon Managed Service for Prometheus にメトリクスを保存し、Amazon Managed Grafana で可視化します。

AWS Distro for OpenTelemetry は、[OpenTelemetry プロジェクト](https://opentelemetry.io/)の安全で本番環境対応の AWS がサポートするディストリビューションです。Cloud Native Computing Foundation の一部である OpenTelemetry は、アプリケーションモニタリングのための分散トレースとメトリクスを収集するためのオープンソース API、ライブラリ、およびエージェントを提供します。AWS Distro for OpenTelemetry を使用すると、アプリケーションを一度だけ計測して、複数の AWS およびパートナーのモニタリングソリューションに相関したメトリクスとトレースを送信できます。コードを変更せずにトレースを収集するには、自動計測エージェントを使用します。AWS Distro for OpenTelemetry はまた、AWS リソースとマネージドサービスからメタデータを収集するため、アプリケーションのパフォーマンスデータと基盤となるインフラストラクチャデータを関連付けることができ、問題解決までの平均時間を短縮できます。AWS Distro for OpenTelemetry を使用して、Amazon Elastic Compute Cloud（EC2）、Amazon Elastic Container Service（ECS）、および Amazon Elastic Kubernetes Service（EKS）on EC2、AWS Fargate、AWS Lambda、およびオンプレミスで実行されるアプリケーションを計測できます。

Amazon Managed Service for Prometheus は、オープンソースの Prometheus プロジェクトと互換性のあるメトリクス用のモニタリングサービスであり、コンテナ環境を安全にモニタリングすることが容易になります。Amazon Managed Service for Prometheus は、人気のある Cloud Native Computing Foundation（CNCF）Prometheus プロジェクトに基づくコンテナのモニタリングソリューションです。Amazon Managed Service for Prometheus は、Amazon Elastic Kubernetes Service や Amazon Elastic Container Service、さらにはセルフマネージド Kubernetes クラスターなどのアプリケーションのモニタリングを開始するために必要な重労働を軽減します。

:::info
CDK Observability Accelerator を使用している場合は、[ADOT コレクター](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/existing-eks-observability-accelerators/existing-eks-adotmetrics-collection-observability/)や[Nvidia DCGM を使用した GPU モニタリング](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/single-new-eks-observability-accelerators/single-new-eks-gpu-opensource-observability/)など、幅広いユースケースをカバーするオープンソース可観測性パターンのコレクションをチェックしてください。
:::

