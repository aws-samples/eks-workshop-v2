---
title: Amazon FSx for Lustre
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service上のワークロードに対する高性能並列ファイルストレージをAmazon FSx for Lustreで実現します。"
tmdTranslationSourceHash: '2822eb2f56eea9b85cc32e5bb6870b87'
---

::required-time

:::tip 開始する前に
このセクションの環境を準備します:

```bash timeout=900 wait=30
$ prepare-environment fundamentals/storage/fsxl
```

これにより、ラボ環境に以下の変更が加えられます:

- FSx for Lustre CSI driverのIAMロールを作成
- EKSクラスターからAmazon FSx for Lustreファイルシステムにアクセスするために必要なルールを持つセキュリティグループを作成
- Amazon FSx for Lustreファイルシステムを作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxl/.workshop/terraform)で確認できます。

:::

[Amazon FSx for Lustre](https://docs.aws.amazon.com/fsx/latest/LustreGuide/what-is.html)は、機械学習、ハイパフォーマンスコンピューティング(HPC)、ビデオ処理、金融モデリング、電子設計自動化(EDA)などのワークロードの高速処理に最適化された、高性能な並列ファイルシステムを提供します。FSx for Lustreは、サブミリ秒のレイテンシ、最大数百ギガバイト/秒のスループット、および数百万のIOPSを実現します。

FSx for Lustreは複数のデプロイタイプをサポートしています:

- **SCRATCH_1およびSCRATCH_2**: データの短期処理に最適化された一時ストレージ。データはレプリケートされず、ファイルサーバーに障害が発生した場合は保持されません。
- **PERSISTENT_1およびPERSISTENT_2**: 同一アベイラビリティゾーン内でデータがレプリケートされ、自動フェイルオーバーをサポートする長期ストレージ。

このラボでは、以下を行います:

- 高性能並列ファイルストレージについて学習
- Kubernetes用のFSx for Lustre CSI Driverの設定とデプロイ
- Kubernetesデプロイメントでの動的プロビジョニングをFSx for Lustreを使用して実装

このハンズオン体験では、高性能で並列的な永続ストレージソリューションのために、Amazon FSx for LustreをAmazon EKSと効果的に使用する方法を実演します。

