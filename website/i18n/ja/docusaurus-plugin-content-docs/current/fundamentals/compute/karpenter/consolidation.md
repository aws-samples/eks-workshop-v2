---
title: "Disruption (Consolidation)"
sidebar_position: 50
kiteTranslationSourceHash: c9be6fd2ae61e4dc79f9e05f66ecdc31
---

Karpenterは、中断（Disruption）の対象となるノードを自動的に検出し、必要に応じて代替ノードをスピンアップします。これは3つの異なる理由で発生します：

- **期限切れ（Expiration）**：デフォルトでは、Karpenterは720時間（30日）後にインスタンスを自動的に期限切れにし、リサイクルを強制することでノードを最新の状態に保ちます。
- **ドリフト（Drift）**：Karpenterは設定の変更（`NodePool`や`EC2NodeClass`など）を検出して必要な変更を適用します。
- **統合（Consolidation）**：コスト効率の良いコンピューティングを運用するための重要な機能であり、Karpenterはクラスターのコンピューティングを継続的に最適化します。たとえば、ワークロードが十分に活用されていないコンピューティングインスタンス上で実行されている場合、それらを少ないインスタンスに統合します。

Disruptionは、`NodePool`の`disruption`ブロックを通じて設定されます。以下に示すのは、すでに私たちの`NodePool`に構成されているポリシーです。

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.spec.expireAfter,spec.disruption"}

1. `expireAfter`はカスタム値に設定されているため、ノードは72時間後に自動的に終了します
2. `WhenEmptyOrUnderutilized`ポリシーにより、ノードが空または十分に活用されていない場合にKarpenterがノードを置き換えることができます

`consolidationPolicy`は、`WhenEmpty`に設定することもでき、その場合はワークロードPodを含まないノードにのみDisruptionを制限します。Disruptionの詳細は、[Karpenterドキュメント](https://karpenter.sh/docs/concepts/disruption/#consolidation)を参照してください。

インフラストラクチャーのスケールアウトは、コスト効率の良いコンピューティングインフラストラクチャーを運用するための方程式の一面に過ぎません。例えば、十分に活用されていないコンピューティングインスタンス上で実行されているワークロードを少ないインスタンスにまとめるなど、継続的に最適化する必要もあります。これにより、ワークロードをコンピューティング上で実行する全体的な効率が向上し、オーバーヘッドが少なくなりコストが削減されます。

`disruption`が`consolidationPolicy: WhenUnderutilized`に設定されている場合の自動統合をトリガーする方法を見てみましょう：

1. `inflate`ワークロードを5から12レプリカにスケールアップし、Karpenterに追加の容量のプロビジョニングを促します
2. ワークロードを5レプリカに戻します
3. Karpenterがコンピューティングを統合する様子を観察します

`inflate`ワークロードを再度スケールアップして、より多くのリソースを消費するようにします：

```bash
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

これにより、このデプロイメントの合計メモリリクエストは約12Giになります。各ノードでkubelet用に予約されている約600Miを考慮すると、これは2つの`m5.large`タイプのインスタンスに収まります：

```bash
$ kubectl get nodes -l type=karpenter --label-columns node.kubernetes.io/instance-type
NAME                                         STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   3m30s   vVAR::KUBERNETES_NODE_VERSION     m5.large
ip-10-42-9-102.us-west-2.compute.internal    Ready    <none>   14m     vVAR::KUBERNETES_NODE_VERSION     m5.large
```

次に、レプリカ数を5に戻します：

```bash wait=90
$ kubectl scale -n other deployment/inflate --replicas 5
```

Karpenterのログを確認して、デプロイメントのスケールインに対応してどのようなアクションを実行したかを確認できます。次のコマンドを実行する前に、5〜10秒ほど待ちましょう：

```bash hook=grep
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'disrupting node(s)' | jq '.'
```

出力には、Karpenterが特定のノードをcordonし、drainしてから終了するプロセスが表示されます：

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:47:05.659Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

これにより、Kubernetesスケジューラはそれらのノード上のPodを残りの容量に配置し、Karpenterが合計1ノードを管理していることが確認できます：

```bash
$ kubectl get nodes -l type=karpenter
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   6m30s   vVAR::KUBERNETES_NODE_VERSION   m5.large
```

Karpenterは、ワークロードの変更に応じて、ノードをより安価なバリアントに置き換えることでさらに統合することもできます。これは、`inflate`デプロイメントのレプリカを1に縮小し、合計メモリリクエストを約1Giにすることで実証できます：

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

Karpenterのログを確認して、コントローラーがどのようなアクションを取ったかを確認できます：

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter -f | jq '.'
```

:::tip
前のコマンドには、フォロー用のフラグ「-f」が含まれており、ログをリアルタイムで監視できます。より小さなノードへの統合は1分以内に完了します。ログを監視してKarpenterコントローラーの動作を確認してください。
:::

出力には、Karpenterが置換による統合を行い、m5.largeノードをProvisioner内で定義されたより安価なc5.largeインスタンスタイプに置き換える様子が表示されます：

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:50:23.249Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

1レプリカの合計メモリリクエストがはるかに低く、約1Giなので、4GBメモリを持つより安価なc5.largeインスタンスタイプで実行する方が効率的です。ノードが置換されたら、新しいノードのメタデータを確認してインスタンスタイプがc5.largeであることを確認できます：

```bash
$ kubectl get nodes -l type=karpenter -o jsonpath="{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{'\n'}{end}"
c5.large
```

