---
title: Amazon FSx for NetApp ONTAP
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service上のワークロードのためにAmazon FSx for NetApp ONTAPによる完全管理型共有ストレージ。"
tmdTranslationSourceHash: 670401c7636880a8ee4032ab8eb3b796
---

::required-time{estimatedLabExecutionTimeMinutes="60"}

:::caution

FSx For NetApp ONTAPファイルシステムと関連インフラのプロビジョニングには最大30分かかる場合があります。このラボを開始する前にこれを考慮し、他のラボよりも`prepare-environment`コマンドの実行に時間がかかることを想定してください。

:::

:::tip 始める前に
このセクションのための環境を準備してください：

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/fsxn
```

:::

[Amazon FSx for NetApp ONTAP](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/what-is-fsx-ontap.html)（FSxN）は、クラウドで完全に管理されたONTAPファイルシステムを起動・実行できるストレージサービスです。ONTAPはNetAppのファイルシステム技術であり、広く採用されているデータアクセスとデータ管理機能を提供します。Amazon FSx for NetApp ONTAPは、オンプレミスのNetAppファイルシステムの機能、パフォーマンス、APIを、完全に管理されたAWSサービスの俊敏性、スケーラビリティ、シンプルさで提供します。

このラボでは以下を行います：

- 永続的なネットワークストレージについて学ぶ
- KubernetesのためのFSx for NetApp ONTAP CSI Driverを設定・デプロイする
- KubernetesデプロイメントでFSx for NetApp ONTAPを使った動的プロビジョニングを実装する

この実践的な経験により、Amazon FSx for NetApp ONTAPとAmazon EKSを効果的に使用して、完全管理型のエンタープライズグレードの永続ストレージソリューションを実現する方法を学びます。

