---
title: "Cluster Access Management API"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "IAMエンティティを使用してAWS認証情報を管理し、ユーザーとグループにAmazon Elastic Kubernetes Serviceへのアクセスを提供します。"
tmdTranslationSourceHash: 8bdc151830673a1edfa62df4bf11ebfe
---

::required-time

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment security/cam
```

これにより、ラボ環境に以下の変更が加えられます：

- 様々なシナリオで引き受けるAWS IAMロールを作成します

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/cam/.workshop/terraform)で確認できます。
:::

プラットフォームエンジニアリングチームは、クラスタ管理者が別個のアイデンティティプロバイダを維持および統合する負担から解放され、AWS Identity and Access Management（IAM）ユーザーおよびロールとKubernetesクラスターの簡素化された構成に依存できるようになりました。AWSのIAMとAmazon EKSの間の統合により、管理者はIAMをKubernetesアイデンティティにマッピングするだけで、監査ログや多要素認証などのIAMセキュリティ機能を活用でき、クラスタの作成中または作成後にEKS APIを通じて、管理者が許可されたIAMプリンシパルとそれに関連するKubernetesのアクセス許可を完全に定義できるようになります。

この章では、Cluster Access Management APIの仕組みを理解し、既存のアイデンティティマッピングコントロールを新しいモデルに変換して、Amazon EKSクラスターへの認証と認可をシームレスに提供する方法を学びます。
