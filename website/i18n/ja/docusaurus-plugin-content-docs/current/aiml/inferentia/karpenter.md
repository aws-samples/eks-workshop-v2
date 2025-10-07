---
title: "Karpenter Setup"
sidebar_position: 20
kiteTranslationSourceHash: d3e1d9c36ab01eadff0094018559d3b2
---

このセクションでは、Inferentiaおよび Trainium EC2インスタンスの作成を可能にするようにKarpenterを構成します。Karpenterはinf2またはtrn1インスタンスを必要とする保留中のPodを検出できます。その後、Karpenterは必要なインスタンスを起動してPodをスケジュールします。

:::tip
Karpenterの詳細については、このワークショップで提供されている[Karpenterモジュール](../../fundamentals/compute/karpenter/index.md)で学ぶことができます。
:::

KarpenterはEKSクラスターにインストールされており、デプロイメントとして実行されています：

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

Karpenterはノードをプロビジョニングするために `NodePool` を必要とします。これは作成する Karpenter の `NodePool` です：

::yaml{file="manifests/modules/aiml/inferentia/nodepool/nodepool.yaml" paths="spec.template.spec.requirements.1,spec.template.spec.requirements.1.values"}

1. このセクションでは、このNodePoolがプロビジョニングできるインスタンスを割り当てます
2. ここでは、このNodePoolがinf2およびtrn1インスタンスのみを作成できるように設定していることがわかります

`NodePool`と`EC2NodeClass`マニフェストを適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/nodepool \
  | envsubst | kubectl apply -f-
```

これでNodePoolがトレーニングとインフェレンスPodの作成準備が整いました。
