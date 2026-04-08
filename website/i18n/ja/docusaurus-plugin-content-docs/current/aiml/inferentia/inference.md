---
title: "AWS Inferentiaで推論を実行"
sidebar_position: 40
tmdTranslationSourceHash: 5c206bfaf5b41e4e71978ecc45f2a279
---

これで、コンパイルされたモデルを使用して、AWS Inferentiaノード上で推論ワークロードを実行することができます。

### 推論用のPodを作成する

推論を実行するイメージを確認しましょう：

```bash
$ echo $AIML_DL_INF_IMAGE
```

これはトレーニングに使用したものとは異なるイメージで、推論用に最適化されています。

これで推論用のPodをデプロイすることができます。これが推論Podを実行するためのマニフェストファイルです：

::yaml{file="manifests/modules/aiml/inferentia/inference/inference.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. 推論では、`nodeSelector`セクションでinf2インスタンスタイプを指定しています。
2. `resources`の`limits`セクションでは、このPodを実行するために再度ニューロンコアが必要であることを指定し、APIを公開します。

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/inference \
  | envsubst | kubectl apply -f-
```

再びKarpenterは、今回はニューロンコアが必要なinf2インスタンスが必要な保留中のPodを検出します。そのため、KarpenterはInferentiaチップを搭載したinf2インスタンスを起動します。以下のコマンドを使用して、インスタンスのプロビジョニングを監視できます：

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
...
{
  "level": "INFO",
  "time": "2024-09-19T18:53:34.266Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-v64vm"
  },
  "namespace": "",
  "name": "aiml-v64vm",
  "reconcileID": "7b5488c5-957a-4051-a657-44fb456ad99b",
  "provider-id": "aws:///us-west-2b/i-0078339b1c925584d",
  "instance-type": "inf2.xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "3920m",
    "ephemeral-storage": "89Gi",
    "memory": "14162Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "18"
  }
}
...
```

推論PodはKarpenterによってプロビジョニングされたノードにスケジュールされるはずです。Podが準備完了の状態になっているか確認します：

:::note
ノードをプロビジョニングし、EKSクラスターに追加してPodを起動するまでに最大12分かかる場合があります。
:::

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=12m pod/inference
```

以下のコマンドを使用して、Podをスケジュールするためにプロビジョニングされたノードに関する詳細情報を取得できます：

```bash
$ kubectl get node -l karpenter.sh/nodepool=aiml -o jsonpath='{.items[0].status.capacity}' | jq .
```

この出力は、このノードが持つ容量を示しています：

```json
{
  "aws.amazon.com/neuron": "1",
  "aws.amazon.com/neuroncore": "2",
  "aws.amazon.com/neurondevice": "1",
  "cpu": "4",
  "ephemeral-storage": "104845292Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "16009632Ki",
  "pods": "58",
  "vpc.amazonaws.com/pod-eni": "18"
}
```

このノードには`aws.amazon.com/neuron`が1つあることがわかります。KarpenterはPodが要求したニューロンコアの数に応じて、このノードをプロビジョニングしました。

### 推論を実行する

これは、Inferentia上のニューロンコアを使用して推論を実行するために使用するコードです：

```file
manifests/modules/aiml/inferentia/inference/inference.py
```

このPythonコードは次のタスクを実行します：

1. 小さな子猫の画像をダウンロードして保存します。
2. 画像を分類するためのラベルを取得します。
3. この画像をインポートし、テンソルに正規化します。
4. 以前に作成したモデルをロードします。
5. 子猫の画像に対して予測を実行します。
6. 予測から上位5つの結果を取得し、コマンドラインに出力します。

このコードをPodにコピーし、以前にアップロードしたモデルをダウンロードして、次のコマンドを実行します：

```bash
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/inference/inference.py inference:/
$ kubectl -n aiml exec inference -- pip install --upgrade boto3==1.40.16 botocore==1.40.16
$ kubectl -n aiml exec inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

出力として上位5つのラベルが返ってきます。ResNet-50の事前トレーニング済みモデルを使用して小さな子猫の画像に対して推論を実行しているので、これらの結果は予想通りです。パフォーマンスを向上させるための次のステップとして、独自の画像データセットを作成し、特定のユースケース向けに独自のモデルをトレーニングすることも可能です。これにより予測結果を向上させることができるでしょう。

これでAmazon EKSでAWS Inferentiaを使用するこのラボは終了です。
