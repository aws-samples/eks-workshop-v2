---
title: "Cluster Proportional Autoscaler"
sidebar_position: 15
sidebar_custom_props: { "module": true }
description: "Cluster Proportional Autoscalerを使用して、Amazon Elastic Kubernetes Serviceクラスターのサイズに比例してワークロードをスケールします。"
tmdTranslationSourceHash: fe1dc05aeb82228068bee57790e9b8ef
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/cpa
```

:::

このラボでは、[Cluster Proportional Autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler)について学び、クラスターのコンピュート数に比例してアプリケーションをスケールする方法を学びます。

Cluster Proportional Autoscaler（CPA）は、クラスター内のノード数に基づいてレプリカをスケールする水平Pod自動スケーラーです。プロポーショナル自動スケーラーコンテナはクラスターのスケジュール可能なノードとコアの数を監視し、それに応じてレプリカの数をリサイズします。この機能は、CoreDNSやクラスター内のノード/Podの数に応じてスケールする他のサービスなど、クラスターのサイズに合わせて自動スケールする必要があるアプリケーションに役立ちます。

CPAは、Pod内でGolang APIクライアントを実行し、APIサーバーに接続してクラスター内のノードとコアの数をポーリングします。スケーリングパラメータとデータポイントはConfigMapを通じて自動スケーラーに提供され、ポーリング間隔ごとにパラメータテーブルを更新して最新の希望するスケーリングパラメータを使用します。他の自動スケーラーとは異なり、CPAはMetrics APIに依存せず、Metrics Serverも必要としません。

![CPA](/docs/fundamentals/workloads/cluster-proportional-autoscaler/cpa.webp)

CPAの主な使用例には以下が含まれます：

- オーバープロビジョニング
- コアプラットフォームサービスのスケーリング
- metrics serverやprometheus adapterを必要としない、シンプルで簡単なワークロードスケーリングメカニズム

## Cluster Proportional Autoscalerが使用するスケーリング方法

### Linear（線形）

- このスケーリング方法では、クラスターで利用可能なノード数またはコア数に直接比例してアプリケーションをスケールします
- `coresPerReplica`または`nodesPerReplica`のいずれかを省略することができます
- `preventSinglePointFailure`が`true`に設定されている場合、コントローラーは1つ以上のノードがあれば少なくとも2つのレプリカを確保します
- `includeUnschedulableNodes`が`true`に設定されている場合、レプリカはノードの総数に基づいてスケールされます。そうでない場合、レプリカはスケジュール可能なノード数のみに基づいてスケールされます（つまり、コードン状態やドレイン中のノードは除外されます）
- `min`、`max`、`preventSinglePointFailure`、`includeUnschedulableNodes`はすべてオプションです。設定されていない場合、`min`はデフォルトで1に、`preventSinglePointFailure`はデフォルトで`false`に、`includeUnschedulableNodes`はデフォルトで`false`になります
- `coresPerReplica`と`nodesPerReplica`はどちらも浮動小数点値です

### ConfigMap for Linear（線形のConfigMap）

```text
data:
  linear: |-
    {
      "coresPerReplica": 2,
      "nodesPerReplica": 1,
      "min": 1,
      "max": 100,
      "preventSinglePointFailure": true,
      "includeUnschedulableNodes": true
    }
```

**線形制御モードの方程式：**

```text
replicas = max( ceil( cores * 1/coresPerReplica ) , ceil( nodes * 1/nodesPerReplica ) )
replicas = min(replicas, max)
replicas = max(replicas, min)
```

### Ladder（ラダー）

- このスケーリング方法では、ノード:レプリカおよび/またはコア:レプリカの比率を決定するためのステップ関数を使用します
- ステップラダー関数は、ConfigMapからコアとノードのスケーリングのデータポイントを使用します。より多くのレプリカ数を生成する検索結果が、ターゲットスケーリング数として使用されます
- `coresPerReplica`または`nodesPerReplica`のいずれかを省略することができます
- レプリカは0に設定することができます（線形モードとは異なり）
- 0レプリカへのスケーリングは、クラスターが成長するにつれてオプション機能を有効にするために使用できます

### ConfigMap for Ladder（ラダーのConfigMap）

```text
data:
  ladder: |-
    {
      "coresToReplicas":
      [
        [ 1, 1 ],
        [ 64, 3 ],
        [ 512, 5 ],
        [ 1024, 7 ],
        [ 2048, 10 ],
        [ 4096, 15 ]
      ],
      "nodesToReplicas":
      [
        [ 1, 1 ],
        [ 2, 2 ]
      ]
    }
```

### Horizontal Pod Autoscalerとの比較

Horizontal Pod AutoscalerはトップレベルのKubernetes APIリソースです。HPAはPodのCPU/メモリ使用率を監視し、レプリカ数を自動的にスケールするクローズドフィードバックループ自動スケーラーです。HPAはMetrics APIに依存し、Metrics Serverを必要としますが、Cluster Proportional AutoscalerはMetrics ServerもMetrics APIも使用しません。

Cluster Proportional AutoscalerはKubernetesリソースで設定されるのではなく、フラグを使用してターゲットワークロードを識別し、スケーリング構成にConfigMapを使用します。CPAはクラスターサイズを監視し、ターゲットコントローラーをスケールするシンプルな制御ループを提供します。CPAの入力はクラスター内のスケジュール可能なコアとノードの数です。

このラボでは、クラスター内のコンピュート量に比例してEKSクラスターのCoreDNSシステムコンポーネントをスケールする方法を示します。
