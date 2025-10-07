---
title: "コンピュート"
sidebar_position: 40
kiteTranslationSourceHash: 649b365d517f1c1b841e97b3b5967531
---

[EKSのコンピュート](https://docs.aws.amazon.com/eks/latest/userguide/eks-compute.html)は、コンテナ化されたワークロードを実行するための複数のオプションを提供しており、それぞれが異なるユースケースや運用要件に合わせて設計されています。

実装に入る前に、EKSと統合して検討するコンピュートオプションの概要を以下に示します：

- [Amazon EKS マネージドノードグループ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)：EKSクラスタ用のEC2ノードのプロビジョニングとライフサイクル管理を自動化します。マネージドノードグループは、新しいAMIやKubernetesバージョンのデプロイメントのローリングアップデートなどの運用活動を簡素化しながら、基盤となるEC2インスタンスに対する完全な制御を提供します。

- [Karpenter](https://karpenter.sh/)：変化するアプリケーションロードに応じて適切なサイズのコンピュートリソースを自動的にプロビジョニングするオープンソースのKubernetesクラスタオートスケーラーです。Karpenterは、必要に応じてノードを迅速に起動および終了することで、アプリケーションの可用性とクラスタの効率性を向上させます。

- [AWS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)：仮想マシンのグループをプロビジョニング、設定、またはスケーリングする必要がないコンテナ用のサーバーレスコンピュートエンジンです。Fargateを使用すると、インフラストラクチャを管理するのではなく、アプリケーションの設計と構築に集中できます。

また、[Kubernetesのコンピュートリソース](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)に関する重要な概念を理解することも重要です：

- [ノード](https://kubernetes.io/docs/concepts/architecture/nodes/)：Kubernetesでコンテナ化されたアプリケーションを実行するワーカーマシンです。各ノードにはPodを実行するために必要なサービスが含まれており、コントロールプレーンによって管理されます。
- [Pod](https://kubernetes.io/docs/concepts/workloads/pods/)：Kubernetesでデプロイ可能な最小単位であり、ストレージとネットワークリソースを共有する1つ以上のコンテナで構成されます。
- [リソースリクエストとリミット](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)：コンテナが必要とするCPUとメモリの量（リクエスト）と使用可能な最大値（リミット）を指定するメカニズムです。
- [ノードアフィニティ](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)：ノードラベルに基づいて、Podがスケジュールされるノードを制約するルールです。
- [TaintとToleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)：Podが不適切なノードにスケジュールされないようにするために連携するメカニズムです。

このセクションで扱う追加のコンピュート考慮事項：

- **Gravitonプロセッサ**：EKSワークロードでより良い価格パフォーマンスを実現するためにAWS GravitonベースのEC2インスタンスを活用する方法を学びます。
- **Spotインスタンス**：アプリケーションの可用性を維持しながらコンピュートコストを削減するためにAmazon EC2 Spotインスタンスを使用する方法を理解します。
- **クラスタオートスケーラー**：従来のクラスタオートスケーリングアプローチを検討し、Karpenterなどの最新の代替手段と比較します。
- **オーバープロビジョニング**：クラスタ内に余剰容量を維持することでPodスケジューリングの遅延を軽減する戦略を実装します。

以下のラボでは、まずマネージドノードグループを使ってEKSコンピュートの基礎を理解し、次に高度なオートスケーリング機能のためのKarpenterを検討し、最後にサーバーレスコンテナ実行のためのFargateを検討します。
