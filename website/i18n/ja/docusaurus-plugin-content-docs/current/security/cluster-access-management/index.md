---
title: "Cluster Access Management API"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "IAMエンティティを使用してAWS認証情報を管理し、ユーザーとグループにAmazon Elastic Kubernetes Serviceへのアクセスを提供します。"
tmdTranslationSourceHash: '5fb59cba574884eb980f48fe6af0d3da'
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

プラットフォームエンジニアリングチームは、クラスター管理者が別個のアイデンティティプロバイダーを維持および統合する負担から解放され、AWS Identity and Access Management（IAM）ユーザーおよびロールとKubernetesクラスターの簡素化された構成に依存できるようになりました。AWSのIAMとAmazon EKSの間の統合により、管理者はIAMをKubernetesアイデンティティにマッピングするだけで、監査ログや多要素認証などのIAMセキュリティ機能を活用でき、クラスターの作成中または作成後にEKS APIを通じて、許可されたIAMプリンシパルとそれに関連するKubernetesのアクセス許可を完全に定義できるようになります。

この章では、Cluster Access Management APIの仕組みを理解し、アクセスエントリーとアクセスポリシーを使用して、Amazon EKSクラスターへの認証と認可を提供する方法を学びます。

