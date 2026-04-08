---
title: "AWS Inferentia を使用した推論"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "AWS Inferentia を使用して Amazon Elastic Kubernetes Service 上で深層学習推論ワークロードを高速化します。"
tmdTranslationSourceHash: c9985ea03c20681a6a0cf025176f16fc
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment aiml/inferentia
```

これにより、お使いのラボ環境に次の変更が加えられます：

- Amazon EKS クラスターに Karpenter をインストールします
- 結果を保存するための S3 バケットを作成します
- Pod が使用する IAM role を作成します
- [AWS Neuron](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/dlc-then-eks-devflow.html) デバイスプラグインをインストールします

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/inferentia/.workshop/terraform)で確認できます。

:::

AWS [Trainium](https://aws.amazon.com/machine-learning/trainium/) と [Inferentia](https://aws.amazon.com/machine-learning/inferentia/) は、クラウドコンピューティング環境での AI モデルのトレーニングと推論タスクをそれぞれ高速化および最適化するために、Amazon によって設計されたカスタムビルドの機械学習アクセラレーターです。

AWS Neuron は、開発者が Trainium と Inferentia チップの両方で機械学習モデルを最適化して実行できるようにするソフトウェア開発キット（SDK）およびランタイムです。Neuron は、これらのカスタム AI アクセラレーターのための統一されたソフトウェアインターフェイスを提供し、開発者が特定のチップアーキテクチャごとにコードを書き直すことなく、そのパフォーマンス上の利点を活用できるようにします。

Neuron デバイスプラグインは、Neuron コアとデバイスを Kubernetes のリソースとして公開します。ワークロードが Neuron コアを必要とする場合、Kubernetes スケジューラはワークロードに適切なノードを割り当てることができます。Karpenter を使用して自動的にノードをプロビジョニングすることもできます。

このラボでは、Inferentia を使用して EKS 上で深層学習推論ワークロードを高速化する方法のチュートリアルを提供します。

このラボでは次のことを行います：

1. Inferentia と Trainium EC2 インスタンスをプロビジョニングするための Karpenter node pool を作成します
2. Trainium インスタンスを使用して AWS Inferentia 用に ResNet-50 事前トレーニング済みモデルをコンパイルします
3. このモデルを後で使用するために S3 バケットにアップロードします
4. 以前のモデルを使用して推論を実行する推論 Pod を起動します

始めましょう。
