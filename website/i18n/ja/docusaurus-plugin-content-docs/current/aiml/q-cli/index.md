---
title: "Amazon Q CLI を使用した EKS の運用"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Amazon Q CLI と Amazon EKS MCP サーバーを使用して Amazon EKS クラスターを管理します。"
tmdTranslationSourceHash: 00741618a8bafac98d4dc03bcc51a8df
---

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment aiml/q-cli
```

これにより、ラボ環境に以下の変更が適用されます：

- Carts アプリケーション用の DynamoDB テーブルを作成します
- DynamoDB テーブルが KMS キーを使用できるようにする KMS キーを作成します
- DynamoDB テーブルが KMS キーを使用できるようにする IAM ロールとポリシーを作成します
- Carts アプリケーションが DynamoDB テーブルにアクセスできるように EKS Pod Identity をセットアップします

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/q-cli/.workshop/terraform)で確認できます。
:::

[Amazon Q デベロッパーのコマンドラインインターフェース (CLI) エージェント](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html)は、高度な AI アシスタントのパワーをコマンドライン環境に直接もたらすことで、ソフトウェア開発体験を変革します。このエージェントは自然言語理解とコンテキスト認識を活用して、複雑なタスクをより効率的に達成するのに役立ちます。Amazon EKS 専用のものを含む[モデルコンテキストプロトコル (MCP)](https://modelcontextprotocol.io/introduction) サーバーのセットと統合し、強力な開発ツールへのアクセスを提供します。複数のターン会話のサポートにより、エージェントとの対話的なコラボレーションが可能になり、より短時間でより多くのことを達成できます。

このセクションでは、以下について学びます：

- 環境での Amazon Q CLI の設定方法
- Amazon EKS 用の MCP サーバーのセットアップ方法
- Amazon Q CLI を使用した EKS クラスターの詳細の取得方法
- Amazon Q CLI を使用した Amazon EKS へのアプリケーションのデプロイ方法
- Amazon Q CLI を使用した Amazon EKS 上のワークロードのトラブルシューティング方法

:::caution プレビュー
このモジュールは現在プレビュー中です。問題が発生した場合は[報告](https://github.com/aws-samples/eks-workshop-v2/issues)してください。
:::
