---
title: "Horizontal Pod Autoscaler"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでのHorizontal Pod Autoscalerによるワークロードの自動スケーリング。"
tmdTranslationSourceHash: fa2252b7e780d07180e66fb2144b655c
---

::required-time

このラボでは、DeploymentやReplicaSet内のPodをスケーリングするために、Horizontal Pod Autoscaler (HPA) について見ていきます。これは、Kubernetes APIリソースとコントローラーとして実装されています。リソースがコントローラーの動作を決定します。Controller Managerは、各HorizontalPodAutoscaler定義で指定されたメトリクスに対してリソース使用率を照会します。コントローラーは、平均CPU使用率、平均メモリ使用率、その他のカスタムメトリクスなどのメトリクスを観測することで、レプリケーションコントローラーやDeployment内のレプリカ数を、ユーザーが指定した目標に合わせて定期的に調整します。コントローラーは、リソースメトリクスAPI（Podごとのリソースメトリクス用）またはカスタムメトリクスAPI（他のすべてのメトリクス用）からメトリクスを取得します。

Kubernetes Metrics Serverは、クラスター内のリソース使用データのスケーラブルかつ効率的なアグリゲーターです。Horizontal Pod Autoscalerが必要とするコンテナメトリクスを提供します。メトリクスサーバーは、Amazon EKSクラスターにデフォルトではデプロイされていません。

<img src={require('@site/static/docs/fundamentals/workloads/horizontal-pod-autoscaler/hpa.webp').default}/>

