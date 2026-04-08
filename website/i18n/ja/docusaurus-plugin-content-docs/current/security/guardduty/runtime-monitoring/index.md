---
title: "EKS ランタイムモニタリング"
sidebar_position: 530
tmdTranslationSourceHash: 2591296ddd62b07b47822d55284b43ee
---

EKS ランタイムモニタリングは、Amazon EKS ノードとコンテナのランタイム脅威検出カバレッジを提供します。GuardDuty セキュリティエージェント（EKS アドオン）を使用して、個々の EKS ワークロードにランタイムの可視性を追加し、例えばファイルアクセス、プロセス実行、権限昇格、ネットワーク接続など、潜在的に侵害された可能性のある特定のコンテナを識別します。

EKS ランタイムモニタリングを有効にすると、GuardDuty は EKS クラスター内のランタイムイベントの監視を開始できます。EKS クラスターに GuardDuty を通じて自動的に、または手動でセキュリティエージェントがデプロイされていない場合、GuardDuty は EKS クラスターのランタイムイベントを受信できなくなります。つまり、エージェントは EKS クラスター内の EKS ノードにデプロイする必要があります。GuardDuty がセキュリティエージェントを自動的に管理するように選択するか、セキュリティエージェントのデプロイと更新を手動で管理することができます。

このラボ演習では、Amazon EKS クラスターにいくつかの EKS ランタイム検出結果を生成します。以下のような検出結果です。

- `Execution:Runtime/NewBinaryExecuted`
- `CryptoCurrency:Runtime/BitcoinTool.B!DNS`
- `Execution:Runtime/NewLibraryLoaded`
- `DefenseEvasion:Runtime/FilelessExecution`
