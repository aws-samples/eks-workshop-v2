---
title: "クラウドバースティング"
sidebar_position: 20
sidebar_custom_props: { "module": false }
weight: 30 # used by test framework
kiteTranslationSourceHash: 90c208a2d82f217beae9075819d3cc65
---

前回のデプロイを基に、「クラウドバースティング」のユースケースをシミュレートするシナリオを探ってみましょう。これにより、EKSハイブリッドノードで実行されているワークロードがピーク需要時に弾力的なクラウドキャパシティを活用して、EC2ノードに「バースト」する方法を実証します。

前回の例と同様に、`nodeAffinity`を使用してハイブリッドノードを優先する新しいワークロードをデプロイします。`preferredDuringSchedulingIgnoredDuringExecution`戦略は、スケジューリング時にはハイブリッドノードを_優先_するが、実行中は_無視_するようKubernetesに指示します。
これは、単一のハイブリッドノードに空きがなくなった場合、これらのポッドはクラスタ内の他の場所、つまりEC2インスタンスに自由にスケジュールされることを意味します。これは素晴らしいことです！これにより、私たちが望んでいたクラウドバースティングが実現されます。しかし、
_IgnoredDuringExecution_の部分は、スケールダウン時にKubernetesがランダムにポッドを削除し、それが実行されている場所を気にしないことを意味します。これは_実行中は無視される_からです。一般的に、Kubernetesは古いポッドから削除します。これは最初にハイブリッドノード上で実行されているポッドになります。私たちはそれを望みません！

Kubernetesのポリシーエンジンである[Kyverno](https://kyverno.io/)をデプロイします。Kyvernoは、ハイブリッドノード（`eks.amazonaws.com/compute-type: hybrid`というラベルが付けられている）にスケジュールされるポッドを監視し、実行中のポッドにアノテーションを追加するポリシーを設定します。
[controller.kubernetes.io/pod-deletion-cost](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost)
アノテーションは、Kubernetesに対して、最初に_コスト_の低いポッドを削除するように指示します。

さっそく取り組んでみましょう。Helmを使用してKyvernoをインストールし、以下に含まれるポリシーをデプロイします：

```bash timeout=300 wait=30
$ helm repo add kyverno https://kyverno.github.io/kyverno/
$ helm install kyverno kyverno/kyverno --version 3.3.7 -n kyverno --create-namespace -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/values.yaml

```

以下の`ClusterPolicy`マニフェストは、EKSハイブリッドノードインスタンスにランディングするポッドを監視し、`pod-deletion-cost`アノテーションを追加するようにKyvernoに指示します。

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml" paths="spec.rules.0.match, spec.rules.0.context.0, spec.rules.0.context.1, spec.rules.0.preconditions, spec.rules.0.mutate"}

1. `Pod/binding`リソースを監視し、ポッドがノードにスケジュールされた時点で
2. アドミッションレビューリクエストから対応する値で`node`変数を設定
3. Kubernetes APIにクエリを実行して、ポッドがスケジュールされたノードに関する情報から`computeType`変数を設定
4. 'hybrid'ノードにスケジュールされたポッドのみを選択
5. ポッドを変更して`pod-deletion-cost`アノテーションを追加

Kyvernoが稼働していることを確認し、ポリシーを適用しましょう：

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready pods --all -n kyverno --timeout=2m
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml
```

次に、サンプルワークロードをデプロイします。これは、前述のnodeAffinityルールを使用して、3つのnginxポッドをハイブリッドノードにデプロイします：

```bash timeout=300 wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/deployment.yaml
```

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/deployment.yaml"}

そのデプロイメントがロールアウトした後、すべてがハイブリッドノードにデプロイされた3つのnginx-deploymentポッドが表示されます。ノードとアノテーションを一度に見ることができるように、kubectlからのカスタム出力を使用しています。Kyvernoが`pod-deletion-cost`アノテーションを適用したことがわかります！

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```

スケールアップしてクラウドにバーストしましょう！ここのnginxデプロイメントは、デモンストレーション目的で不合理な量のCPU（200m）を要求しています。つまり、ハイブリッドノードには約8つのレプリカを配置できます。ポッドを15レプリカにスケールアップすると、それらをスケジュールする余地がなくなります。`preferredDuringSchedulingIgnoredDuringExecution`アフィニティポリシーを使用しているため、まずハイブリッドノードから始めます。スケジュールできないものは、他の場所（クラウドインスタンス）にスケジュールすることが許可されます。

通常、スケーリングはCPU、メモリ、GPU可用性、またはキューの深さなどの外部要因に基づいて自動的に行われます。ここでは、強制的にスケールアップします：

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 15
```

ここで、カスタム列を使用して`kubectl get pods`を実行すると、追加のポッドがワークショップEKSクラスタに接続されたEC2インスタンスにデプロイされていることがわかります。Kyvernoは、ハイブリッドノードに配置されたすべてのポッドに`pod-deletion-cost`アノテーションを適用し、EC2に配置されたすべてのポッドにはそれを適用していません。スケールダウンすると、Kubernetesはまず_コスト_が低い、つまりアノテーションのないポッドをすべて削除します。その後、Kubernetesは他のすべてのポッドを同等と見なし、通常の削除ロジックが適用されます。それでは実際に見てみましょう：

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                                          ANNOTATIONS
nginx-deployment-7474978d4f-8269p   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-8f6cg   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-bjbvx   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-f55rj   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-jrcsl   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-mstwv   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-q8nkj   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-smc9f   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-ss76l   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-tbzf2   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-txxlw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-wqbsd   ip-10-42-154-155.us-west-2.compute.internal   <none>
```

サンプルデプロイメントを再び3にスケールダウンしましょう。これにより、ハイブリッドノード上で実行されている3つのポッドが残り、元の状態に戻ります：

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 3
```

最後に、確認のために、ハイブリッドノード上で実行されている3つのレプリカに戻っていることを確認しましょう：

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```
