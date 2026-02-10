---
title: "事前学習済みモデルのコンパイル"
sidebar_position: 30
tmdTranslationSourceHash: a2378b389bd03104b94889bfbb008551
---

AWS Inferentiaを活用するモデルを使用するには、AWS Neuron SDKを使用してAWS Inferentia用にコンパイルする必要があります。

これはInferentia用にモデルをコンパイルするために使用するコードです：

```file
manifests/modules/aiml/inferentia/compiler/trace.py
```

このコードは事前学習済みのResNet-50モデルを読み込み、評価モードに設定します。ここではモデルに追加のトレーニングデータを追加していないことに注意してください。その後、AWS Neuron SDKを使用してモデルを保存します。

EKSクラスタにPodをデプロイし、AWS Inferentia用のサンプルモデルをコンパイルします。AWS Inferentia用のモデルをコンパイルするには、[AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/)が必要です。このSDKはAWSが提供する[Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers)に含まれています。

### Device Pluginのインストール

DLCがNeuronコアを使用するためには、それらを公開する必要があります。[Neuron device pluginのKubernetesマニフェストファイル](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8)はNeuronコアをDLCに公開します。これらのマニフェストファイルはEKSクラスタに事前にインストールされています。

PodがNeuronコアを必要とする場合、KubernetesスケジューラーはPodをスケジュールするために、InferentiaまたはTrainiumノードをプロビジョニングできます。

実行する予定のイメージを確認します：

```bash
$ echo $AIML_DL_TRN_IMAGE
```

### トレーニング用のPodを作成する

このコードをEKS上のPodで実行します。これはPodを実行するためのマニフェストファイルです：

::yaml{file="manifests/modules/aiml/inferentia/compiler/compiler.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. `nodeSelector`セクションでは、このPodを実行したいインスタンスタイプを指定しています。この場合はtrn1インスタンスです。
2. `resources`の`limits`セクションでは、このPodを実行するためにneuronコアが必要であることを指定しています。これによりNeuron Device PluginはPodにneuron APIを公開するように指示します。

次のコマンドを実行してPodを作成します：

```bash timeout=900
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/compiler \
  | envsubst | kubectl apply -f-
```

Karpenterはtrn1インスタンスとNeuronコアを必要とする保留中のPodを検出し、要件を満たすtrn1インスタンスを起動します。次のコマンドを使用してインスタンスのプロビジョニングを監視できます：

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
{
  "level": "INFO",
  "time": "2024-09-19T18:44:08.919Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-hp9wm"
  },
  "namespace": "",
  "name": "aiml-hp9wm",
  "reconcileID": "b38f0b3c-f146-4544-8ddc-ca73574c97f0",
  "provider-id": "aws:///us-west-2b/i-06bc9a7cb6f92887c",
  "instance-type": "trn1.2xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "7910m",
    "ephemeral-storage": "89Gi",
    "memory": "29317Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "17"
  }
}
```

PodはKarpenterによってプロビジョニングされたノードにスケジュールされるはずです。Podが準備完了の状態になっているか確認します：

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=10m pod/compiler
```

:::warning
このコマンドは最大で10分かかる場合があります。
:::

次に、モデルをコンパイルするためのコードをPodにコピーして実行します：

```bash timeout=240
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/compiler/trace.py compiler:/
$ kubectl -n aiml exec compiler -- python /trace.py

....
Downloading: "https://download.pytorch.org/models/resnet50-0676ba61.pth" to /root/.cache/torch/hub/checkpoints/resnet50-0676ba61.pth
100%|-------| 97.8M/97.8M [00:00<00:00, 165MB/s]
.
Compiler status PASS
```

最後に、モデルを作成済みのS3バケットにアップロードします。これにより、後でラボでモデルを使用できるようになります。

```bash
$ kubectl -n aiml exec compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/

upload: ./resnet50_neuron.pt to s3://eksworkshop-inference20230511204343601500000001/resnet50_neuron.pt
```

