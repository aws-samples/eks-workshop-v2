---
title: "Karpenter"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Karpenterを使用してAmazon Elastic Kubernetes Serviceのコンピュートを自動的に管理します。"
tmdTranslationSourceHash: 6f927d12193cafc42102d5e204835a9e
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=900 wait=30
$ prepare-environment autoscaling/compute/karpenter
```

これにより、ラボ環境に以下の変更が適用されます：

- Karpenterが必要とするさまざまなIAMロールやその他のAWSリソースをインストールします

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/karpenter/.workshop/terraform)で確認できます。

:::

このラボでは、Kubernetesのためのオープンソースの自動スケーリングプロジェクトである[Karpenter](https://github.com/aws/karpenter)について見ていきます。Karpenterは、スケジュールできないポッドの集約リソースリクエストを監視し、スケジューリングの遅延を最小限に抑えるためにノードの起動と終了を決定することで、アプリケーションのニーズに合った適切なコンピュートリソースを数分ではなく数秒で提供するように設計されています。

<img src={require('@site/static/docs/fundamentals/compute/karpenter/karpenter-diagram.webp').default}/>

Karpenterの目標は、Kubernetesクラスター上で実行されるワークロードの効率性とコストを改善することです。Karpenterは以下のように動作します：

- Kubernetesスケジューラによってスケジュール不可能とマークされたポッドを監視します
- ポッドによって要求されるスケジューリング制約（リソースリクエスト、ノードセレクタ、アフィニティ、トレレーション、トポロジースプレッド制約）を評価します
- ポッドの要件を満たすノードをプロビジョニングします
- 新しいノードにポッドをスケジュールします
- ノードが不要になった場合は削除します
