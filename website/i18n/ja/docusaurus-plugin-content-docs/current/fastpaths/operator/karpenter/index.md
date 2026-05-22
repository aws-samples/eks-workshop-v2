---
title: "EKS Auto Mode によるオートスケーリング"
sidebar_position: 20
description: "EKS Auto Mode で Amazon Elastic Kubernetes Service の自動的なコンピュート管理を実現します。"
tmdTranslationSourceHash: "1f33ea5e2868f81be011bb2e7762c98b"
---

:::tip セットアップ済みの内容
Amazon EKS Auto Mode クラスターには、**Karpenter** によって提供される完全マネージド型オートスケーリング機能が含まれており、すぐに使えるコンピュートスケーリングが有効になっています。
:::

このラボでは、EKS Auto Mode がクラスターに自動コンピュートスケーリングを提供する仕組みを探ります。Auto Mode には、運用負荷を最小限に抑える包括的なマネージド機能スイートの一部として、完全マネージド型の [Karpenter](https://github.com/aws/karpenter) 機能が含まれています。オートスケーリング機能は、スケジュール不可能な Pod の集約リソース要求を観察し、スケジューリングレイテンシを最小限に抑えるためにノードを起動および終了する決定を行うことで、アプリケーションのニーズに合わせた適切なコンピュートリソースを数分ではなく数秒で提供するように設計されています。

<img src={require('@site/static/img/fastpaths/operator/karpenter/karpenter-diagram.webp').default} style={{maxWidth: '600px'}} />

EKS Auto Mode のオートスケーリングは以下のように機能します：

- Kubernetes スケジューラーがスケジュール不可能とマークした Pod を監視
- Pod が要求するスケジューリング制約（リソース要求、ノードセレクタ、アフィニティ、Toleration、Pod Topology Spread Constraints）を評価
- Pod の要件を満たすノードをプロビジョニング
- 新しいノードで実行するように Pod をスケジューリング
- ノードが不要になったときにノードを削除

:::info
EKS Auto Mode では、Karpenter は AWS によって完全に管理され、クラスター外で実行されます。セルフマネージド Karpenter とは異なり、Karpenter Pod をデプロイ、スケール、またはアップグレードする必要はありません。すべての運用面は AWS によって処理され、NodePool と NodeClass の設定に対する制御は保持されます。
:::

Auto Mode が完全マネージド型オートスケーリングを提供するため、ワークロードのためにノードがプロビジョニングされる方法を制御する NodePool の設定に直接移ることができます。

