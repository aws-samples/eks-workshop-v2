---
title: "モデルの提供"
sidebar_position: 40
kiteTranslationSourceHash: 19c1062b963727f2866b6dc90cfc71bd
---

[vLLM](https://github.com/vllm-project/vllm)は、効率的なメモリ管理を通じて大規模言語モデル（LLM）のパフォーマンスを最適化するために特別に設計されたオープンソースの推論・サービングエンジンです。MLコミュニティで人気のある推論ソリューションとして、vLLMはいくつかの主要な利点を提供します：

- **効率的なメモリ管理**：PagedAttentionテクノロジーを使用してGPU/アクセラレーターメモリの使用を最適化
- **高いスループット**：複数のリクエストの同時処理を可能にする
- **AWS Neuronサポート**：AWS InferentiaおよびTrainiumアクセラレーターとのネイティブ統合
- **OpenAI互換API**：OpenAIのAPIの代替として使用でき、統合を簡素化

AWS Neuron特有の機能として、vLLMは以下を提供します：

- Neuron SDKおよびランタイムのネイティブサポート
- Inferentia/Trainiumアーキテクチャ向けの最適化されたメモリ管理
- 効率的なスケーリングのための継続的なモデルロード
- AWS Neuronプロファイリングツールとの統合

このラボでは、`neuronx-distributed-inference`フレームワークでコンパイルされた[Mistral-7B-v0.3モデル](https://mistral.ai/news/announcing-mistral-7b)を使用します。このモデルは能力とリソース要件のバランスが取れており、Trainiumを搭載した私たちのEKSクラスターへのデプロイに適しています。

モデルをデプロイするために、モデルとウェイトをロードするvLLMベースのコンテナイメージを使用する標準的なKubernetes Deploymentを使用します：

::yaml{file="manifests/modules/aiml/chatbot/vllm.yaml"}

必要なリソースを作成しましょう：

```bash
$ kubectl create namespace vllm
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/chatbot/vllm.yaml
```

作成されたリソースを確認します：

```bash
$ kubectl get deployment -n vllm
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mistral   0/1     1            0           33s
$ kubectl get service -n vllm
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mistral   ClusterIP   172.16.149.89   <none>        8080/TCP   33m
```

モデルの初期化プロセスには数分かかります。vLLM Podは以下の段階を経ます：

1. Karpenterが Trainium インスタンスをプロビジョニングするまでPending状態のままになる
2. initコンテナを使用してHugging Faceからモデルをホストファイルシステムのパスにダウンロード
3. vLLMコンテナイメージをダウンロード（約10GB）
4. vLLMサービスを起動
5. ファイルシステムからモデルをロード
6. ポート8080でHTTPエンドポイント経由でモデルの提供を開始

これらの段階を通じてPodの状態を監視するか、モデルがロードされている間に次のセクションに進むことができます。

待つことを選択した場合は、PodがInit状態に移行するのを監視できます（Ctrl + Cで終了）：

```bash test=false
$ kubectl get pod -n vllm --watch
NAME                       READY   STATUS    RESTARTS   AGE
mistral-6889d675c5-2l6x2   0/1     Pending   0          21s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          30s
mistral-6889d675c5-2l6x2   0/1     Pending   0          38s
mistral-6889d675c5-2l6x2   0/1     Pending   0          50s
mistral-6889d675c5-2l6x2   0/1     Init:0/1   0          50s
# Podがinit状態に達したら終了
```

モデルをダウンロードしているinitコンテナのログを確認できます（Ctrl + Cで終了）：

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c model-download -f
[...]
Downloading 'weights/tp0_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/dAuF3Bw92r-GdZ-yzT84Iweq-RQ=.6794a3d7f2b1d071399a899a42bcd5652e83ebdd140f02f562d90b292ae750aa.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp0_sharded_checkpoint.safetensors
Downloading 'weights/tp1_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/eEdQSCIfRYQ2putRDwZhjh7Te8E=.14c5bd3b07c4f4b752a65ee99fe9c79ae0110c7e61df0d83ef4993c1ee63a749.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp1_sharded_checkpoint.safetensors

Model download is complete.
# ログがここまで到達したら終了
```

initコンテナが完了したら、vLLMコンテナの起動時のログを監視できます（Ctrl + Cで終了）：

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c vllm -f
[...]
INFO 09-30 04:43:37 [launcher.py:36] Route: /v2/rerank, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /invocations, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /metrics, Methods: GET
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     10.42.114.242:38674 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.114.242:50134 - "GET /health HTTP/1.1" 200 OK
# ログがここまで到達したら終了
```

これらのステップを完了したか、モデルの初期化中に次に進むことを決めたら、次のタスクに進むことができます。

