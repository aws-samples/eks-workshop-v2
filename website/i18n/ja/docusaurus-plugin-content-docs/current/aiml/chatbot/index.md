---
title: "vLLMによる大規模言語モデル"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceで AWS Trainiumを使用してディープラーニング推論ワークロードを加速します。"
tmdTranslationSourceHash: 220afe5f35f32481c86cd27864418036
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment aiml/chatbot
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon EKSクラスターにKarpenterをインストールします
- Amazon EKSクラスターにAWS Load Balancer Controllerをインストールします

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/chatbot/.workshop/terraform)で確認できます。

:::

[Mistral 7B](https://mistral.ai/en/news/announcing-mistral-7b)は、パフォーマンスと効率性のバランスを提供するために設計された73億のパラメータを持つオープンソースの大規模言語モデル（LLM）です。膨大な計算リソースを必要とするより大きなモデルとは異なり、Mistral 7Bは実用的なリソース要件を維持しながら、印象的な機能を提供します。テキスト生成、補完、情報抽出、データ分析、複雑な推論タスクに優れています。

このモジュールでは、Amazon EKS上でMistral 7Bをデプロイして効率的に提供する方法を探ります。以下の内容を学びます：

1. 加速されたML（機械学習）ワークロード用の必要なインフラストラクチャのセットアップ
2. AWS Trainiumアクセラレーターを使用したモデルのデプロイ
3. モデル推論エンドポイントの構成とスケーリング
4. デプロイされたモデルとのシンプルなチャットインターフェースの統合

モデル推論を加速するために、[Trn1](https://aws.amazon.com/ai/machine-learning/trainium/)インスタンスファミリーを通じてAWS Trainiumを活用します。これらの目的に合わせて構築されたアクセラレーターは、ディープラーニングワークロード向けに最適化されており、標準的なCPUベースのソリューションと比較してモデル推論に大幅なパフォーマンス向上を提供します。

私たちの推論アーキテクチャは、LLM向けに特別に設計された高スループットかつメモリ効率の良い推論エンジンである[vLLM](https://github.com/vllm-project/vllm)を活用します。vLLMはOpenAI互換のAPIエンドポイントを提供し、既存のアプリケーションとの統合を容易にします。
