---
title: "Neuronプラグインのインストール"
sidebar_position: 20
tmdTranslationSourceHash: ca9a05d53409b6d28986cc62f0620f83
---

KubernetesがAWS Neuronアクセラレータを認識し効果的に利用できるようにするには、Neuronデバイスプラグインをインストールする必要があります。このプラグインは、NeuronコアとデバイスをKubernetes内でスケジュール可能なリソースとして公開する役割を担い、ワークロードから要求された場合に適切にNeuronアクセラレーションを持つノードをプロビジョニングできるようにします。

[AWS Neuron SDK](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/)は、AWS InferentiaとTrainiumチップ上で機械学習ワークロードを実行できるようにするソフトウェア開発キットです。デバイスプラグインは、Kubernetesのリソース管理機能とこれらの特殊なアクセラレータを橋渡しする重要なコンポーネントです。

公式の[Neuronデバイスプラグイン Helmチャート](https://gallery.ecr.aws/neuron/neuron-helm-chart)を使用してNeuronデバイスプラグインをインストールしましょう：

```bash
$ helm upgrade --install neuron-helm-chart oci://public.ecr.aws/neuron/neuron-helm-chart \
  --namespace kube-system --version 1.3.0 \
  --values ~/environment/eks-workshop/modules/aiml/chatbot/neuron-values.yaml \
  --wait
```

DaemonSetが正常に作成されたことを確認できます：

```bash
$ kubectl get ds neuron-device-plugin -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
neuron-device-plugin   0         0         0       0            0           <none>          10s
```

まだNeuronデバイスを提供するコンピュートノードがクラスター内にないため、現在はPodが実行されていません。次のセクションでTrainiumインスタンスをプロビジョニングすると、DaemonSetは自動的にそれらのノードにデバイスプラグインをデプロイし、Neuronデバイスをワークロードで利用できるようになります。
