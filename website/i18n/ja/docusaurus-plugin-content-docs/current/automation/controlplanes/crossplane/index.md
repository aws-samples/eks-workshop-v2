---
title: "Crossplane"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Build a cloud native control plane with Crossplane on Amazon Elastic Kubernetes Service."
tmdTranslationSourceHash: f6d69f91180d666646e4baf1d121461e
---

::required-time

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=300 wait=120
$ prepare-environment automation/controlplanes/crossplane
```

これにより、ラボ環境に次の変更が加えられます：

- CrossplaneとAWSプロバイダをAmazon EKSクラスタにインストールします

これらの変更を適用するTerraformは[ここ](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/crossplane/.workshop/terraform)で確認できます。

:::

[Crossplane](https://crossplane.io/)は、Cloud Native Computing Foundation（CNCF）のオープンソースプロジェクトで、Kubernetesクラスタをユニバーサルコントロールプレーンに変換します。これにより、プラットフォームチームは複数のベンダーからインフラストラクチャを組み立て、アプリケーションチームがコードを書かずに消費できる高レベルのセルフサービスAPIを公開できます。

Crossplaneは、あらゆるインフラストラクチャやマネージドサービスをオーケストレーションするためにKubernetesクラスタを拡張します。お気に入りのツールと既存のプロセスを使用して、バージョン管理、管理、デプロイ、消費できる高レベルの抽象化にCrossplaneの細かいリソースを構成できます。

![EKS with Dynamodb](/docs/automation/controlplanes/crossplane/eks-workshop-crossplane.webp)

Crossplaneを使用すると、次のことが可能です：

1. Kubernetesクラスタから直接クラウドインフラストラクチャをプロビジョニングおよび管理する
2. 複雑なインフラストラクチャセットアップを表すカスタムリソースを定義する
3. アプリケーション開発者向けにインフラストラクチャ管理を簡素化する抽象化レイヤーを作成する
4. 複数のクラウドプロバイダー間で一貫したポリシーとガバナンスを実装する

このモジュールでは、AWSリソースを管理するためにCrossplaneを使用する方法を探り、特にサンプルアプリケーション用のDynamoDBテーブルのプロビジョニングと構成に焦点を当てます。
