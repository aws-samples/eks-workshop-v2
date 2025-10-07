---
title: Amazon FSx for OpenZFS
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceのワークロード用の、Amazon FSx for OpenZFSによる完全マネージド型の高性能で伸縮自在なファイルストレージ。"
kiteTranslationSourceHash: 456aff728bf007f40feada9eef333db7
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=900 wait=30
$ prepare-environment fundamentals/storage/fsxz
```

これにより、ラボ環境に以下の変更が適用されます：

- IAM OIDCプロバイダーの作成
- EKSクラスターからAmazon FSx for OpenZFSファイルシステムにアクセスするために必要なルールを持つ新しいセキュリティグループの作成
- Amazon FSx for OpenZFS Single-AZ 2ファイルシステムの作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxz/.workshop/terraform)で確認できます。

:::

[Amazon FSx for OpenZFS](https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/what-is-fsx.html)は、NFSv3およびNFSv4経由でアクセス可能な、フルマネージド型の高性能共有ファイルシステムを提供します。共有データセットには、マイクロ秒レベルのレイテンシーで数百万IOPSと最大21 GB/秒のスループットでアクセスできます。FSx for OpenZFSには、ゼロスペースのスナップショット、ゼロスペースのクローン、データレプリケーション、シンプロビジョニング、ユーザークォータ、圧縮など、多くのエンタープライズ機能も含まれています。

2つの異なるストレージクラスがあります：オールSSDベースのストレージクラスとインテリジェントティアリングストレージクラスです。SSDストレージクラスを利用するファイルシステムは、一貫したマイクロ秒レベルのレイテンシーを提供します。インテリジェントティアリングファイルシステムは、キャッシュされた読み取りにはマイクロ秒レベルのレイテンシー、書き込みには1-2ミリ秒のレイテンシー、読み取りキャッシュミスには数十ミリ秒のレイテンシーを提供します。インテリジェントティアリングストレージクラスは、データセットと共に拡大・縮小する完全に弾力的なストレージ容量を提供し、消費された容量のみに対してS3のような料金で課金されます。

このラボでは、以下を行います：

- 永続的なネットワークストレージについて学ぶ
- Kubernetes用FSx for OpenZFS CSIドライバーの設定とデプロイ
- KubernetesデプロイメントでFSx for OpenZFSを使用した動的プロビジョニングの実装

この実践的な経験を通じて、Amazon EKSでAmazon FSx for OpenZFSを効果的に使用して、フルマネージド型の高性能、エンタープライズ機能を備えた、弾力的な永続ストレージソリューションを実現する方法を示します。
