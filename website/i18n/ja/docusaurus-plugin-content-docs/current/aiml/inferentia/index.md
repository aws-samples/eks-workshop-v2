---
title: "AWS Inferentia を使用した推論"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Inferentia を使用して Amazon Elastic Kubernetes Service 上で深層学習推論ワークロードを高速化します。"
kiteTranslationSourceHash: c47d679f5f9ef6d61d8383e300238990
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment aiml/inferentia
```

これにより、お使いのラボ環境に次の変更が加えられます：

- Amazon EKSクラスターにKarpenterをインストールします
- 結果を保存するためのS3バケットを作成します
- ポッドが使用するIAMロールを作成します
- [AWS Neuron](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/dlc-then-eks-devflow.html)デバイスプラグインをインストールします

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/inferentia/.workshop/terraform)で確認できます。

:::

AWS [Trainium](https://aws.amazon.com/machine-learning/trainium/)と[Inferentia](https://aws.amazon.com/machine-learning/inferentia/)は、クラウドコンピューティング環境でのAIモデルのトレーニングと推論タスクをそれぞれ高速化および最適化するために、Amazonによって設計されたカスタムビルドの機械学習アクセラレーターです。

AWS Neuronは、開発者がTrainiumとInferentiaチップの両方で機械学習モデルを最適化して実行できるようにするソフトウェア開発キット（SDK）およびランタイムです。Neuronは、これらのカスタムAIアクセラレーターのための統一されたソフトウェアインターフェイスを提供し、開発者が特定のチップアーキテクチャごとにコードを書き直すことなく、そのパフォーマンス上の利点を活用できるようにします。

Neuronデバイスプラグインは、NeuronコアとデバイスをKubernetesのリソースとして公開します。ワークロードがNeuronコアを必要とする場合、Kubernetesスケジューラはワークロードに適切なノードを割り当てることができます。Karpenterを使用して自動的にノードをプロビジョニングすることもできます。

このラボでは、InferentiaをEKS上で深層学習推論ワークロードを高速化するために使用する方法のチュートリアルを提供します。
このラボでは次のことを行います：

1. InferentiaとTrainium EC2インスタンスをプロビジョニングするためのKarpenterノードプールを作成します
2. TrainiumインスタンスでAWS Inferentia用にResNet-50事前トレーニング済みモデルをコンパイルします
3. このモデルを後で使用するためにS3バケットにアップロードします
4. 以前のモデルを使用して推論を実行する推論ポッドを起動します

始めましょう。

