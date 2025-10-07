---
title: "AWS CodePipeline"
sidebar_position: 5
sidebar_custom_props: { "module": true }
description: "AWS CodePipeline Amazon Elastic Kubernetes Service action."
kiteTranslationSourceHash: a4bce05779292471a1a1073eda371390
---

:::tip 始める前に

このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment automation/continuousdelivery/codepipeline
```

このコマンドは以下を実行します：

- コンテナイメージを保存するためのAmazon ECRリポジトリを作成
- このラボ用の新しいAWS CodePipelineを作成

:::

AWS CodePipelineは、ソフトウェアをリリースするために必要なステップをモデル化、視覚化、自動化することができる継続的デリバリーサービスです。AWS CodePipelineを使用すると、コードのビルド、プレプロダクション環境へのデプロイ、アプリケーションのテスト、本番環境へのリリースという完全なリリースプロセスをモデル化します。その後、AWS CodePipelineはコードが変更されるたびに、定義されたワークフローに従ってアプリケーションをビルド、テスト、デプロイします。パートナーツールや独自のカスタムツールをリリースプロセスのどの段階にも統合して、エンドツーエンドの継続的デリバリーソリューションを形成することができます。

CodePipelineを使用すると、コンテナ化されたアプリケーションのソースコード、クラスターの設定、コンテナイメージのビルド、およびこれらのイメージを環境（EKSクラスター）にデプロイすることを1つのワークフローで管理できます。

