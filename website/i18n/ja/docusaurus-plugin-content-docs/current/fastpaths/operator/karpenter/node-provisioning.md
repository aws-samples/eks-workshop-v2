---
title: "自動ノードプロビジョニング"
sidebar_position: 40
tmdTranslationSourceHash: 'f72bb599bbdb8974b106cac05c633d86'
---

まず、スケジュールできない Pod のニーズに応じて、Karpenter が適切なサイズの EC2 インスタンスを動的にプロビジョニングする方法を確認します。これにより、EKS クラスター内の未使用のコンピュートリソースを削減できます。

前のセクションで確認した NodePool は、Karpenter が使用できる特定のインスタンスファミリーを指定していました。それらは以下の通りです。

| インスタンスファミリー | 世代 |   OS   | アーキテクチャ |
| ----------------- | ---------- | ------ | ------------ |
| `c`, `m`, `r`     |     >4     | Linux  | amd64        |

この広範な設定により、Karpenter は要件に基づいて適切なサイズのインスタンスを選択するための幅広い選択肢を持つことができます。

いくつかの Pod を作成して、Auto Mode の Karpenter ベースのオートスケーリングがどのように適応するか見てみましょう。現在、Karpenter によって管理されているノードが 2 つあるはずです:

```bash
$ kubectl get node -l karpenter.sh/nodepool=general-purpose

NAME                  STATUS   ROLES    AGE   VERSION
i-07fd006840ed07309   Ready    <none>   17h   v1.33.4-eks-e386d34
i-0e209b70f1d2dfae0   Ready    <none>   14h   v1.33.4-eks-e386d34
```

Karpenter にスケールアウトをトリガーさせるために、以下の Deployment を使用します:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/automode/scale/deployment.yaml" paths="spec.replicas,spec.template.spec.containers.0.image,spec.template.spec.containers.0.resources"}

1. 初期状態では 0 レプリカを実行するように指定されており、後でスケールアップします
3. シンプルな `pause` コンテナイメージを使用します
4. 各 Pod に `1Gi` のメモリをリクエストします

:::info pause コンテナとは？
この例では、以下のイメージを使用していることに気付くでしょう:

`public.ecr.aws/eks-distro/kubernetes/pause`

これは実際のリソースを消費せず、すぐに起動する小さなコンテナで、スケーリングシナリオのデモンストレーションに最適です。この特定のラボの多くの例でこれを使用します。
:::

この Deployment を適用します:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/automode/scale
deployment.apps/inflate created
```

それでは、Karpenter が最適化された決定を行っていることを実証するために、意図的にこの Deployment をスケールしてみましょう。1Gi のメモリをリクエストしているので、Deployment を 5 レプリカにスケールすると、合計 5Gi のメモリがリクエストされることになります。

進める前に、上記の表から Karpenter がどのインスタンスをプロビジョニングすると思いますか？どのインスタンスタイプをプロビジョニングしてほしいですか？

Deployment をスケールします:

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

この操作は 1 つ以上の新しい EC2 インスタンスを作成するため、時間がかかります。`kubectl` を使用して完了するまで待つことができます:

```bash timeout=200
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

それでは、Karpenter が実行したアクションをイベントをリストして確認しましょう。イベントがリストされるまで 5-10 秒待ちます。

```bash wait=10
$ kubectl events | grep -i 'NodeClaim'
```

新しいノードが起動されていることを示す出力が表示されるはずです。

```
2m55s       Normal    Launched                  nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Launched, Status: Unknown -> True, Reason: Launched
2m52s       Normal    DisruptionBlocked         nodeclaim/general-purpose-5c74h   Nodeclaim does not have an associated node
2m39s       Normal    Registered                nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Registered, Status: Unknown -> True, Reason: Registered
2m36s       Normal    Initialized               nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Initialized, Status: Unknown -> True, Reason: Initialized
2m36s       Normal    Ready                     nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Ready, Status: Unknown -> True, Reason: Ready
12m         Normal    Unconsolidatable          nodeclaim/general-purpose-nhtc7   Can't replace with a cheaper node
```

Karpenter は、スケジュールされる予定のすべての Pod を収容できる十分な大きさで、同時にコストが低い最も適切なインスタンスタイプを見つけます。

:::info
最も安いインスタンスタイプ以外が選択される場合もあります。例えば、作業しているリージョンでその最も安いインスタンスタイプに残りの容量がない場合などです。
:::

クラスター内の利用可能なノードを再度リストしてみましょう。

```bash
$ kubectl get nodes \
  -L beta.kubernetes.io/instance-type \
  -L kubernetes.io/arch \
  -L kubernetes.io/os \
  --sort-by=.metadata.creationTimestamp

NAME                  STATUS   ROLES    AGE   VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   20h   v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0e209b70f1d2dfae0   Ready    <none>   17h   v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   60m   v1.33.4-eks-e386d34   m5a.large       amd64   linux
```

プールに追加された最後のノードが、このページの前半で示した `NodePool` 設定テーブルに従っていることがわかります。

Karpenter は NodeClaim と呼ばれる Kubernetes ネイティブオブジェクトを通じてノードを追跡します。これはオブジェクトなので、設定も確認できます:

```bash
$ kubectl get nodeclaims.karpenter.sh  -o wide
NAME                    TYPE        CAPACITY    ZONE         NODE                  READY   AGE     IMAGEID                 ID                                      NODEPOOL          NODECLASS   DRIFTED
general-purpose-dh59z   m5a.large   on-demand   us-west-2b   i-0d3ed392f96f22793   True    5m58s   ami-00e71b7a43dd16dec   aws:///us-west-2b/i-0d3ed392f96f22793   general-purpose   default
general-purpose-mw4sf   c6a.large   on-demand   us-west-2a   i-0078b61779fc13053   True    30h     ami-00e71b7a43dd16dec   aws:///us-west-2a/i-0078b61779fc13053   general-purpose   default
general-purpose-wp7wg   c6a.large   on-demand   us-west-2c   i-0c1ceaeeb6ed1bfb6   True    8m5s    ami-00e71b7a43dd16dec   aws:///us-west-2c/i-0c1ceaeeb6ed1bfb6   general-purpose   default
```

この簡単な例は、EKS Auto Mode の Karpenter ベースのオートスケーリングが、コンピュート容量を必要とするワークロードのリソース要件に基づいて、適切なインスタンスタイプを動的に選択できることを示しています。これは、Cluster Autoscaler のようなノードプールを中心としたモデルとは根本的に異なります。ノードプールでは、単一のノードグループ内のインスタンスタイプは一貫した CPU とメモリの特性を持つ必要があります。

