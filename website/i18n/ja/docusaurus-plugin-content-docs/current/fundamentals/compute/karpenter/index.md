---
title: "Karpenter"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Karpenterを使用してAmazon Elastic Kubernetes Serviceのコンピュートを自動的に管理します。"
tmdTranslationSourceHash: 27dcc8f0e942bf8c8a10c360417174c3
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=900 wait=30
$ prepare-environment autoscaling/compute/karpenter
```

これにより、ラボ環境に以下の変更が適用されます：

- Karpenterが必要とするさまざまなIAM roleやその他のAWSリソースをインストールします

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/karpenter/.workshop/terraform)で確認できます。

:::

このラボでは、Kubernetesのためのオープンソースの自動スケーリングプロジェクトである[Karpenter](https://github.com/aws/karpenter)について見ていきます。Karpenterは、スケジュールできないPodの集約リソースリクエストを監視し、スケジューリングの遅延を最小限に抑えるためにノードの起動と終了を決定することで、アプリケーションのニーズに合った適切なコンピュートリソースを数分ではなく数秒で提供するように設計されています。

<img src={require('@site/static/docs/fundamentals/compute/karpenter/karpenter-diagram.webp').default}/>

Karpenterの目標は、Kubernetesクラスター上で実行されるワークロードの効率性とコストを改善することです。Karpenterは以下のように動作します：

- Kubernetesスケジューラによってスケジュール不可能とマークされたPodを監視します
- Podによって要求されるスケジューリング制約（リソースリクエスト、ノードセレクタ、アフィニティ、Toleration、Pod Topology Spread Constraints）を評価します
- Podの要件を満たすノードをプロビジョニングします
- ノードが不要になった場合は、そのノードを中断（disrupt）します

