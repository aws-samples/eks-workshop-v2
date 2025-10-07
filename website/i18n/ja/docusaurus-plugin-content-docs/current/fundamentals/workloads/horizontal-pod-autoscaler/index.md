---
title: "Horizontal Pod Autoscaler"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceでの水平ポッドオートスケーラーによるワークロードの自動スケーリング。"
kiteTranslationSourceHash: 13bfb29470ac67b559072855b7d73067
---

::required-time

このラボでは、デプロイメントやレプリカセット内のポッドをスケーリングするために、Horizontal Pod Autoscaler (HPA) について見ていきます。これは、K8s APIリソースとコントローラーとして実装されています。リソースがコントローラーの動作を決定します。Controller Managerは、各HorizontalPodAutoscalerの定義で指定されたメトリクスに対してリソース使用率を照会します。コントローラーは、レプリケーションコントローラーやデプロイメントのレプリカ数を、平均CPU使用率、平均メモリ使用率、その他のカスタムメトリクスなどのメトリクスを観測し、ユーザーが指定した目標に合わせて定期的に調整します。コントローラーは、リソースメトリクスAPI（ポッドごとのリソースメトリクス用）またはカスタムメトリクスAPI（他のすべてのメトリクス用）からメトリクスを取得します。

Kubernetes Metrics Serverは、クラスター内のリソース使用データをスケーラブルかつ効率的に集約するものです。Horizontal Pod Autoscalerが必要とするコンテナメトリクスを提供します。メトリクスサーバーはAmazon EKSクラスターにデフォルトでデプロイされていません。

<img src={require('./assets/hpa.webp').default}/>

