---
title: "コンピュートのプロビジョニング"
sidebar_position: 30
kiteTranslationSourceHash: 13f766113a1438b0acc552e45a497040
---

このラボでは、Karpenterを使用して、加速された機械学習推論用に特別に設計されたAWS Trainiumノードをプロビジョニングします。TrainiumはAWSの専用ML高速化プロセッサーで、Mistral-7Bモデルのような推論ワークロードを実行する際の高性能とコスト効率性を提供します。

:::tip
Karpenterについて詳しく知りたい場合は、このワークショップの[Karpenterモジュール](../../fundamentals/compute/karpenter/index.md)をチェックしてください。
:::

KarpenterはすでにEKSクラスタにインストールされており、Deploymentとして実行されています：

```bash
$ kubectl get deployment karpenter -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

Trainiumインスタンスをプロビジョニングするために使用するKarpenter NodePoolの設定を確認しましょう：

::yaml{file="manifests/modules/aiml/chatbot/nodepool-trn1.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. このNodePoolは、デモンストレーションの目的でPodを特定のターゲットにするために、すべての新しいノードに`provisionerType: Karpenter`というKubernetesラベルを付けるよう設定されています。Karpenterによって複数のノードが自動スケーリングされるため、`instanceType: trn1.2xlarge`のような追加のラベルも追加され、このKarpenterノードが`trainium-trn1`プールに割り当てられるべきことを示しています。
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)はインスタンスタイプやゾーンなどのノードプロパティを定義することをサポートしています。この例では、`karpenter.sh/capacity-type`を最初にKarpenterがオンデマンドインスタンスのみをプロビジョニングするように制限し、また`karpenter.k8s.aws/instance-type`で特定のインスタンスタイプのサブセットに限定しています。他にどのようなプロパティが[利用可能かはこちら](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes)で確認できます。
3. Taintは、ノードが一連のPodを排除できるようにする特定のプロパティセットを定義します。このプロパティはマッチングするラベルであるTolerationと連携して機能します。TolerationとTaintは連携して、Podが適切なノードに正しくスケジュールされることを保証します。他のプロパティについては、[このリソース](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)で詳しく学べます。
4. NodePoolは、それによって管理されるCPUとメモリの量に制限を定義できます。この制限に達すると、Karpenterはその特定のNodePoolに関連する追加のキャパシティをプロビジョニングしなくなり、合計コンピュートに上限を設けます。

NodePoolを作成しましょう：

```bash
$ cat ~/environment/eks-workshop/modules/aiml/chatbot/nodepool-trn1.yaml \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/trainium-trn1 created
nodepool.karpenter.sh/trainium-trn1 created
```

正しく展開されたら、NodePoolsを確認します：

```bash
$ kubectl get nodepool
NAME                NODECLASS           NODES   READY   AGE
trainium-trn1       trainium-trn1       0       True    31s
```

上記のコマンドから、NodePoolが正しくプロビジョニングされていることがわかります。これにより、Karpenterは必要に応じて新しいノードをプロビジョニングできます。次のステップでMLワークロードをデプロイすると、Karpenterは指定したリソース要求と制限に基づいて必要なTrainiumインスタンスを自動的に作成します。
