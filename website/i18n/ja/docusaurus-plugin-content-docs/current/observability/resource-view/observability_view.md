---
title: "Observability"
sidebar_position: 30
kiteTranslationSourceHash: 4864a8b132bce526aab8be8bd4718917
---

アプリケーション、ネットワーク、インフラストラクチャを注意深く監視することは、最適なパフォーマンスを確保し、ボトルネックを特定し、問題を迅速に解決するために不可欠です。
AWSの可観測性を使用すると、ネットワーク、インフラストラクチャ、アプリケーションでテレメトリを収集、相関付け、集約、分析して、システムの動作、パフォーマンス、健全性に関するインサイトを得ることができます。これらのインサイトは、問題をより迅速に検出、調査、修正するのに役立ちます。

EKSコンソールのObservabilityタブでは、EKSクラスターのエンドツーエンドの可観測性に関する包括的なビューを提供します。以下に示すように、PrometheusメトリクスまたはCloudWatchメトリクスのいずれかを使用して、クラスター、インフラストラクチャ、アプリケーションメトリクスを収集し、[Amazon Managed Service for Prometheus](https://aws.amazon.com/prometheus/)に送信します。[Amazon Managed Grafana](https://aws.amazon.com/grafana/)を使用して、ダッシュボードでメトリクスを視覚化し、アラートを作成できます。

Prometheusは、スクレイピングと呼ばれるプルベースのモデルを通じて、クラスターからメトリクスを検出して収集します。スクレイパーは、クラスターインフラストラクチャとコンテナ化されたアプリケーションからデータを収集するように設定されています。**Add scraper**を使用して、クラスター用のスクレイパーを設定します。

CloudWatch Observabilityアドオンを通じて、クラスターでCloudWatch Observabilityを有効にすることができます。アドオンタブに移動し、CloudWatch Observabilityアドオンをインストールして、CloudWatch Application SignalsとContainer Insightsを有効にし、テレメトリをCloudWatchに取り込み始めます。

![Insights](/img/resource-view/observability-view.jpg)

