---
title: "Kiro CLIでEKSを操作する"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Kiro CLIとAmazon EKS MCPサーバーを使用してAmazon EKSクラスターを管理します。"
tmdTranslationSourceHash: 'c4697cfea8da9d705b8b19b12f0ef021'
---

:::tip 始める前に
このセクションの環境を準備します:

```bash timeout=300 wait=30
$ prepare-environment aiml/kiro-cli
```

これにより、ラボ環境に以下の変更が加えられます:

- Cartsアプリケーション用のDynamoDBテーブルを作成
- DynamoDBテーブル用のKMSキーを作成
- DynamoDBテーブルがKMSキーを使用できるようにするIAMロールとポリシーを作成
- CartsアプリケーションがDynamoDBテーブルにアクセスできるようにEKS Pod Identityを設定

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/kiro-cli/.workshop/terraform)で確認できます。
:::

[Kiro CLI](https://kiro.dev/docs/cli/installation/)は、高度なAIアシスタントの機能をコマンドライン環境に直接もたらすことで、ソフトウェア開発体験を変革します。このエージェントは自然言語理解とコンテキスト認識を活用して、複雑なタスクをより効率的に実行できるようサポートします。Amazon EKS専用のサーバーを含む一連の[Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction)サーバーと統合され、強力な開発ツールへのアクセスを提供します。マルチターン会話のサポートにより、エージェントとの協調的なやり取りが可能になり、より短時間でより多くのことを達成できます。

このセクションでは、以下について学習します:

- 環境でKiro CLIを設定する
- Amazon EKS用のMCPサーバーをセットアップする
- Kiro CLIを使用してEKSクラスターの詳細を取得する
- Kiro CLIを使用してAmazon EKSにアプリケーションをデプロイする
- Kiro CLIを使用してAmazon EKS上のワークロードをトラブルシューティングする

