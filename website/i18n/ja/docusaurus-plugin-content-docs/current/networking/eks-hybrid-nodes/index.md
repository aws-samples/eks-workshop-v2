---
title: "Amazon EKS Hybrid Nodes"
sidebar_position: 50
sidebar_custom_props: { "module": true }
weight: 10 # used by test framework
description: "Amazon EKS Hybrid Nodesは、クラウド、オンプレミス、およびエッジ環境全体でKubernetesの管理を統合し、より高いスケーラビリティ、可用性、および効率性を実現します。"
tmdTranslationSourceHash: 1b97045e0b4f9db807839e7f5ada93fe
---

::required-time{estimatedLabExecutionTimeMinutes="30"}

:::caution プレビュー
このモジュールは現在プレビュー中です。問題が発生した場合は[報告してください](https://github.com/aws-samples/eks-workshop-v2/issues)。
:::

Amazon EKS Hybrid Nodesは、クラウド、オンプレミス、およびエッジ環境全体でKubernetesの管理を統合し、ワークロードをどこでも実行する柔軟性を提供しながら、より高い可用性、スケーラビリティ、および効率性を実現します。環境全体でKubernetesの運用とツールを標準化し、一元的なモニタリング、ロギング、アイデンティティ管理のためのAWSサービスとネイティブに統合します。EKS Hybrid Nodesは、Kubernetesコントロールプレーンの可用性とスケーラビリティをAWSにオフロードすることで、オンプレミスおよびエッジでのKubernetesの管理に必要な時間と労力を削減します。EKS Hybrid Nodesは、追加のハードウェア投資なしに既存のインフラストラクチャ上で実行でき、近代化を加速します。

Amazon EKS Hybrid Nodesでは、前払いコミットメントや最低料金はなく、ハイブリッドノードがAmazon EKSクラスターに接続されている間、ハイブリッドノードのvCPUリソースに対して1時間ごとに課金されます。価格の詳細については、[Amazon EKSの料金](https://aws.amazon.com/eks/pricing/)を参照してください。

:::danger
EC2上でのEKS Hybrid Nodesの実行はサポートされている構成ではありません。
このモジュールでは、ラボとデモンストレーションの目的でのみEC2上でEKS Hybrid Nodesを実行しています。ユーザーは任意のリージョンでAmazon EKSを実行し、オンプレミスおよびエッジでEKS Hybrid Nodesを実行する必要があります。
:::

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=30
$ prepare-environment networking/eks-hybrid-nodes
```

:::

以下のアーキテクチャ図は、私たちが構築するものの高レベルな例です。AWS Transit Gatewayを介してEKSクラスターをシミュレートされた「リモート」ネットワークに接続します。本番環境では、リモートネットワークは通常、AWS Direct ConnectまたはAWS Site-to-Site VPNを介して接続されます。これらの接続は、クラスターVPCのTransit Gatewayに接続されます。「リモート」ネットワークには、ラボ目的でEKS Hybrid Nodeとして使用される単一のEC2ノードが実行されます。このノードでは、IDEからSSHを介してコマンドを実行します。EC2上でのEKS Hybrid Nodesの実行は**サポートされていない**ことに注意することが重要です。ここではデモ目的でのみ行っています。

![アーキテクチャ図](/docs/networking/eks-hybrid-nodes/lab_environment.png)

