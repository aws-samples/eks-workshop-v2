---
title: "Kubernetes Event-Driven Autoscaler (KEDA)"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceのワークロードを自動でKEDAでスケーリングする"
kiteTranslationSourceHash: 7e242b2451442e01ef5ea9951d4742fa
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/keda
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS Load Balancer Controllerに必要なIAMロールを作成します
- AWS Load Balancer ControllerのHelmチャートをデプロイします
- KEDAオペレーターに必要なIAMロールを作成します
- UIワークロード用のIngressリソースを作成します

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/workloads/keda/.workshop/terraform)で確認できます。

:::

このラボでは、[Kubernetes Event-Driven Autoscaler (KEDA)](https://keda.sh/)を使用してデプロイメント内のポッドをスケールする方法を見ていきます。前回のHorizontal Pod Autoscaler (HPA)のラボでは、HPAリソースを使用して平均CPU使用率に基づいてデプロイメント内のポッドを水平方向にスケールする方法を学びました。しかし、ワークロードによっては外部イベントやメトリクスに基づいてスケールする必要があります。KEDAは、Amazon SQSのキューの長さやCloudWatchの他のメトリクスなど、様々なイベントソースからのイベントに基づいてワークロードをスケールする機能を提供します。KEDAは60以上の[スケーラー](https://keda.sh/docs/scalers/)を各種メトリクスシステム、データベース、メッセージングシステムなど多様なソースに対応しています。

KEDAは、Helmチャートを使用してKubernetesクラスターにデプロイできる軽量なワークロードです。KEDAは、Horizontal Pod Autoscalerのような標準的なKubernetesコンポーネントと連携して、DeploymentやStatefulSetをスケールします。KEDAを使用すると、これらの様々なイベントソースで選択的にスケールしたいワークロードを選ぶことができます。

