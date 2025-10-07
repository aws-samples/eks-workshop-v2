---
title: Amazon EFS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceのワークロード向けのサーバーレスで完全弾力的なファイルストレージをAmazon Elastic File Systemで実現。"
kiteTranslationSourceHash: 9933fa49f44d9f120280c54b2bb9af48
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/efs
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon EFS CSIドライバー用のIAMロールを作成
- Amazon EFSファイルシステムを作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform)で確認できます。

:::

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)（Amazon EFS）は、アプリケーションを中断することなく、需要に応じてペタバイト規模まで自動的に拡張するサーバーレスで完全に弾力的なファイルシステムを提供します。ファイルの追加や削除時に容量をプロビジョニングおよび管理する必要がなく、AWSクラウドサービスおよびオンプレミスリソースとの併用に最適です。

このラボでは、以下を学習します：

- 永続的なネットワークストレージについて
- Kubernetes用のEFS CSIドライバーを設定およびデプロイ
- KubernetesデプロイメントでEFSを使用した動的プロビジョニングを実装

この実践的な体験を通じて、スケーラブルで永続的なストレージソリューションのためにAmazon EFSをAmazon EKSで効果的に使用する方法を学びます。

