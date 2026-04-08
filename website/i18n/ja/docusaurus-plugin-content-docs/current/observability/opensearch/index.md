---
title: "OpenSearch による観測可能性"
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "OpenSearch を中心に Amazon Elastic Kubernetes Service の観測可能性機能を構築します。"
tmdTranslationSourceHash: "1c8c349b1fcc283207a7fba13ee5879a"
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=3600 wait=30
$ prepare-environment observability/opensearch
```

これにより、ラボ環境に以下の変更が加えられます：

- 以前の EKS ワークショップモジュールからリソースをクリーンアップ
- Amazon OpenSearch Service ドメインをプロビジョニング（以下の**注意**を参照）
- CloudWatch Logs から OpenSearch に EKS コントロールプレーンログをエクスポートするために使用される Lambda 関数の設定

**注意**：AWS イベントに参加している場合、時間を節約するために OpenSearch ドメインは事前にプロビジョニングされています。一方、自分のアカウント内でこれらの指示に従っている場合、上記の `prepare-environment` ステップで OpenSearch ドメインがプロビジョニングされますが、完了までに最大 30 分かかる場合があります。

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/.workshop/terraform)で確認できます。

:::

このラボでは、観測可能性のための [OpenSearch](https://opensearch.org/about.html) の使用について探ります。OpenSearch は、データの取り込み、検索、視覚化、分析に使用されるコミュニティ主導のオープンソースの検索および分析スイートです。OpenSearch はデータストアと検索エンジン（OpenSearch）、視覚化およびユーザーインターフェース（OpenSearch Dashboards）、およびサーバーサイドのデータコレクター（Data Prepper）で構成されています。私たちは、インタラクティブなログ分析、リアルタイムのアプリケーションモニタリング、検索などを簡単に実行できるようにするマネージドサービスである [Amazon OpenSearch Service](https://aws.amazon.com/opensearch-service/) を使用します。

Kubernetes イベント、コントロールプレーンログ、および Pod ログが Amazon EKS から Amazon OpenSearch Service にエクスポートされ、これら 2 つの Amazon サービスが観測可能性を向上させるためにどのように連携できるかを示します。
