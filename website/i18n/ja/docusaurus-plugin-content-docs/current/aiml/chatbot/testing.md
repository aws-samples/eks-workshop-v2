---
title: "モデルのテスト"
sidebar_position: 70
kiteTranslationSourceHash: 516338b2f62fd7d74433fc23b352b2f3
---

現時点で、Mistral-7Bモデルは利用可能か、または利用可能になる直前のはずです。以下のコマンドを実行して確認できます。このコマンドはモデルがまだ実行されていない場合、実行されるまでブロックします：

```bash wait=10 timeout=700
$ kubectl rollout status --timeout=600s deployment/mistral -n vllm
```

## 直接APIコールでのテスト

Deploymentが正常になったら、`curl`を使用してエンドポイントの簡単なテストを実行できます。これにより、モデルが推論リクエストを正しく処理できることを確認できます。

次のペイロードを送信します：

```file
manifests/modules/aiml/chatbot/post.json
```

テストコマンドを実行します：

```bash
$ export payload=$(cat ~/environment/eks-workshop/modules/aiml/chatbot/post.json)
$ kubectl run curl-test --image=curlimages/curl \
 --rm -itq --restart=Never -- \
 curl http://mistral.vllm:8080/v1/completions \
 -H "Content-Type: application/json" \
 -d "$payload" | jq
{
  "id": "cmpl-af24a0c6ef904f0bb7e2be29e317096b",
  "object": "text_completion",
  "created": 1759208218,
  "model": "/models/mistral-7b-v0.3",
  "choices": [
    {
      "index": 0,
      "text": "1. Red 2. Orange 3. Yellow 4. Green 5. Blue 6. Indigo 7. Violet\n\nThe order of the colors in a rainbow is determined by the wavelength of the light. Red has the longest wavelength, and violet has the shortest. This order is often remembered by the acronym ROYGBIV, which stands for Red, Orange, Yellow, Green, Blue, Indigo, and Violet.",
      "logprobs": null,
      "finish_reason": "length",
      "stop_reason": null,
      "prompt_logprobs": null
    }
  ],
  "usage": {
    "prompt_tokens": 13,
    "total_tokens": 113,
    "completion_tokens": 100,
    "prompt_tokens_details": null
  },
  "kv_transfer_params": null
}
```

この例では、プロンプト `The names of the colors in the rainbow are:` を送信し、LLMは虹の色を順番に説明するテキストで補完しました。LLMの非決定論的な性質により、受け取る応答は、特に温度値が0より大きい場合、ここに示されているものと若干異なる場合があります。

## チャットインターフェースのテスト

より対話的な体験のために、デモウェブストアにアクセスして統合されたチャットインターフェースを使用できます：

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

画面の右下に「Chat」ボタンが表示されます：

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com">
<img src={require('./assets/home-chat.webp').default}/>
</Browser>

このボタンをクリックすると、小売店アシスタントにメッセージを送信できるチャットウィンドウが表示されます：

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com">
<img src={require('./assets/chat-bot.webp').default}/>
</Browser>

## 結論

これで、vLLMを使用してTrainiumインスタンスでAmazon EKSで推論を実行し、さまざまなアプリケーションで消費できるモデルエンドポイントを提供する方法を正常にデモンストレーションできました。このアーキテクチャは、目的に合わせて構築されたMLアクセラレーターの能力とKubernetesの柔軟性とスケーラビリティを組み合わせて、アプリケーションのためのコスト効率の良いAI機能を可能にします。

vLLMが提供するOpenAI互換APIにより、このソリューションを既存のアプリケーションやフレームワークと簡単に統合でき、独自のインフラストラクチャ内で大規模言語モデルを活用することができます。
