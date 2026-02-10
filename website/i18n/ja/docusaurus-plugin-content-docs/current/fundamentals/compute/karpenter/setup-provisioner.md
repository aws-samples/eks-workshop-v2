---
title: "ノードプールの設定"
sidebar_position: 30
tmdTranslationSourceHash: fd22bceabe4a17094247eeb8c77db36a
---

Karpenterの設定は`NodePool` CRD（Custom Resource Definition）の形式で提供されます。単一のKarpenter `NodePool`は、さまざまな形状のポッドを処理することができます。Karpenterは、ラベルやアフィニティなどのポッド属性に基づいてスケジューリングとプロビジョニングの決定を行います。クラスターには複数の`NodePool`を設定できますが、ここではまず基本的なものを宣言します。

Karpenterの主な目的の一つは、キャパシティ管理を簡素化することです。他の自動スケーリングソリューションに慣れている方は、Karpenterが**グループレス自動スケーリング**と呼ばれる異なるアプローチを取っていることに気づくかもしれません。従来の他のソリューションでは、**ノードグループ**の概念を制御要素として使用し、提供されるキャパシティの特性（オンデマンド、EC2スポット、GPUノードなど）を定義し、クラスター内のグループの希望するスケールを制御していました。AWSでは、ノードグループの実装は[Auto Scalingグループ](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)に対応しています。Karpenterを使用すると、異なる計算ニーズを持つ複数のタイプのアプリケーションを管理する際に発生する複雑さを回避することができます。

まずはKarpenterが使用するカスタムリソースを適用することから始めましょう。最初に、一般的なキャパシティ要件を定義する`NodePool`を作成します：

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements, spec.limits"}

1. `NodePool`に、すべての新しいノードに`type: karpenter`というKubernetesラベルを付けるよう指示しています。これにより、デモンストレーションの目的でKarpenterノードを特定のポッドでターゲットにすることができます。
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)は、インスタンスタイプやゾーンなどのノードプロパティを定義することをサポートしています。この例では、`karpenter.sh/capacity-type`を設定して、Karpenterがオンデマンドインスタンスのプロビジョニングに限定するとともに、`node.kubernetes.io/instance-type`で特定のインスタンスタイプのサブセットに限定しています。[どのようなプロパティが利用可能か](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes)についてはこちらで詳しく学ぶことができます。ワークショップ中にさらにいくつか取り組む予定です。
3. `NodePool`は、それによって管理されるCPUとメモリの量に制限を定義することができます。この制限に達すると、Karpenterはその特定の`NodePool`に関連する追加のキャパシティをプロビジョニングしなくなり、総計算リソースに上限を設けます。

また、AWSに適用される特定の設定を提供する`EC2NodeClass`も必要です：

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodeclass.yaml" paths="spec.role,spec.subnetSelectorTerms,spec.tags"}

1. KarpenterによってプロビジョニングされるEC2インスタンスに適用されるIAMロールを割り当てます
2. `subnetSelectorTerms`を使用して、KarpenterがEC2インスタンスを起動するサブネットを検索できます。これらのタグは、ワークショップ用に提供されている関連するAWSインフラストラクチャに自動的に設定されています。`securityGroupSelectorTerms`は、EC2インスタンスにアタッチされるセキュリティグループに対して同様の機能を果たします。
3. 作成されるEC2インスタンスに適用されるタグのセットを定義し、会計とガバナンスを可能にします。

これで、Karpenterにクラスターの容量のプロビジョニングを開始するために必要な基本的な要件を提供しました。

次のコマンドで`NodePool`と`EC2NodeClass`を適用します：

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/nodepool \
  | envsubst | kubectl apply -f-
```

ワークショップを通じて、以下のコマンドでKarpenterのログを調査し、その動作を理解することができます：

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | jq '.'
```
