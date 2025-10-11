---
title: "チャットボットの設定"
sidebar_position: 60
kiteTranslationSourceHash: b928d52fd7b5a0df33f46847cca1ea37
---

サンプル小売アプリケーションには、お客様が自然言語を使用して店舗とやり取りできる組み込みのチャットインターフェースが含まれています。この機能は、お客様が商品を見つけたり、おすすめを受け取ったり、店舗ポリシーについての質問に答えたりするのに役立ちます。このモジュールでは、このチャットコンポーネントを設定して、vLLMを通じて提供されるMistral-7Bモデルを使用します。

UIコンポーネントを再設定して、チャットボット機能を有効にし、vLLMエンドポイントを指すようにしましょう：

```kustomization
modules/aiml/chatbot/deployment/kustomization.yaml
Deployment/ui
```

この設定では、次の重要な変更が行われます：

1. UIインターフェースでチャットボットコンポーネントを有効にします
2. アプリケーションがvLLMのOpenAI互換APIで動作するOpenAIモデルプロバイダーを使用するよう設定します
3. OpenAIエンドポイント形式で必要な適切なモデル名を指定します
4. エンドポイントURLを`http://mistral.vllm:8080`に設定し、vLLM DeploymentのKubernetes Serviceに接続します

これらの変更を実行中のアプリケーションに適用しましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

これらの変更を適用することで、UIにローカルにデプロイされた言語モデルに接続するチャットインターフェースが表示されるようになります。次のセクションでは、この設定をテストして、AI駆動のチャットボットを実際に動作させてみましょう。

:::note
UIはvLLMエンドポイントを使用するように設定されましたが、モデルがリクエストに応答できるようになるには完全に読み込まれる必要があります。テスト時に遅延やエラーが発生した場合は、モデルがまだ初期化中である可能性があります。
:::
