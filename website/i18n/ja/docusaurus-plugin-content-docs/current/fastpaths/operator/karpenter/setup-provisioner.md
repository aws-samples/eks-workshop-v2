---
title: "Karpenter 設定の確認"
sidebar_position: 30
tmdTranslationSourceHash: 71e7d00dc015ad2a1c4b15a4580cf76d
---

EKS Auto Mode は、すぐに使える機能として完全マネージド型の Karpenter を提供します。Karpenter の設定は `NodePool` CRD (Custom Resource Definition) の形式で提供されます。単一の Karpenter `NodePool` は、さまざまな Pod 形状を処理できます。Karpenter は、ラベルやアフィニティなどの Pod 属性に基づいてスケジューリングとプロビジョニングの決定を行います。クラスターには複数の `NodePool` を持つことができますが、当面は Auto Mode がデフォルトで設定する NodePool を使用します。

Karpenter の主な目的の 1 つは、容量管理を簡素化することです。他の自動スケーリングソリューションに精通している場合、Karpenter が **グループレス自動スケーリング** と呼ばれる異なるアプローチを採用していることに気づいたかもしれません。他のソリューションでは、従来 **ノードグループ** という概念を制御要素として使用し、提供される容量の特性（つまり：オンデマンド、EC2 Spot、GPU ノードなど）を定義し、クラスター内のグループの望ましいスケールを制御していました。AWS では、ノードグループの実装は [Auto Scaling グループ](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) と一致します。Karpenter を使用すると、異なるコンピューティングニーズを持つ複数のタイプのアプリケーションを管理する際に生じる複雑さを回避できます。

まず、Karpenter が使用する既存のリソースを確認することから始めましょう。まず、一般的な容量要件を定義するデフォルトの `NodePool` を確認します：

```bash 
$ kubectl get nodepools general-purpose -o yaml

apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  annotations:
    karpenter.sh/nodepool-hash: "4012513481623584108"
    karpenter.sh/nodepool-hash-version: v3
  generation: 1
  labels:
    app.kubernetes.io/managed-by: eks
  name: general-purpose
  resourceVersion: "57384"
spec:
  disruption:
    budgets:
    - nodes: 10%
    consolidateAfter: 30s
    consolidationPolicy: WhenEmptyOrUnderutilized
  template:
    metadata: {}
    spec:
      expireAfter: 336h
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: default
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values:
        - on-demand
      - key: eks.amazonaws.com/instance-category
        operator: In
        values:
        - c
        - m
        - r
      - key: eks.amazonaws.com/instance-generation
        operator: Gt
        values:
        - "4"
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
      - key: kubernetes.io/os
        operator: In
        values:
        - linux
      terminationGracePeriod: 24h0m0s
```

このデフォルトの `NodePool` リソースに加えて、ワークロードに対する異なる分離要件やインフラストラクチャ要件を指定するために、カスタム `NodePool` リソースを作成することもできます。以下は、そのための主な考慮事項です。

1. `NodePool` は、すべての新しいノードを Kubernetes ラベル `type: karpenter` で起動するように設定されており、これにより、デモンストレーション目的で Pod を Karpenter ノードに特定してターゲットできるようになります。
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) は、インスタンスタイプやゾーンなどのノードプロパティの定義をサポートしています。この設定では、`karpenter.sh/capacity-type` を設定して、最初は Karpenter をオンデマンドインスタンスのプロビジョニングに制限し、`node.kubernetes.io/instance-type` を設定して特定のインスタンスタイプのサブセットに制限しています。他にどのようなプロパティが [利用可能かはこちら](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes) で確認できます。ワークショップ中にさらにいくつか取り組みます。
3. `NodePool` は、それが管理する CPU とメモリの量に制限を定義できます。この制限に達すると、Karpenter はその特定の `NodePool` に関連する追加容量をプロビジョニングせず、総コンピューティングに上限を提供します。

`NodePool` に加えて、Karpenter にはもう 1 つ重要なリソース、`NodeClass` があります。前の `NodePool` 設定の `nodeClassRef` の下で参照されている `NodeClass` を確認できます。この `NodeClass` も EKS Auto Mode によって事前にプロビジョニングされています。以下がその設定です。

```bash
$ kubectl get nodeclass default -o yaml

apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  annotations:
    eks.amazonaws.com/nodeclass-hash: "495408067366721138"
    eks.amazonaws.com/nodeclass-hash-version: v2
  finalizers:
  - eks.amazonaws.com/termination
  generation: 1
  labels:
    app.kubernetes.io/managed-by: eks
  name: default
  resourceVersion: "304263"
spec:
  ephemeralStorage:
    iops: 3000
    size: 80Gi
    throughput: 125
  networkPolicy: DefaultAllow
  networkPolicyEventLogs: Disabled
  role: eks-workshop-auto-auto-node
  securityGroupSelectorTerms:
  - id: sg-0c70efd097a74a4cf
  snatPolicy: Random
  subnetSelectorTerms:
  - id: subnet-096bfe6623a87be3f
  - id: subnet-09e84ab4eee5d16bb
  - id: subnet-02a87ab5b226b952d
```

1. `role` 属性は、Karpenter によってプロビジョニングされる EC2 インスタンスに適用される IAM role を割り当てます
2. `subnetSelectorTerms` は、Karpenter が EC2 インスタンスを起動するサブネットを検索するために使用できます。
3. `securityGroupSelectorTerms` は、EC2 インスタンスにアタッチされるセキュリティグループに対して同じ機能を実現します。

これらのリソースがすべて EKS Auto Mode によって管理されているため、Karpenter はクラスターの容量のプロビジョニングを開始するために必要な基本要件を満たしています。

実際に動作を確認するために、ハンズオンを行いましょう。

