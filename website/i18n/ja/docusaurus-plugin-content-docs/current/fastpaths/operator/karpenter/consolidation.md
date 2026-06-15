---
title: "ディスラプション (統合)"
sidebar_position: 50
tmdTranslationSourceHash: '917a7d9fa2b5eba8c737d35dfecde14b'
---

Karpenter は、ディスラプションの対象となるノードを自動的に検出し、必要に応じて代替ノードを起動します。これは3つの異なる理由で発生する可能性があります:

- **有効期限**: デフォルトでは、Karpenter は 720時間（30日）後にインスタンスを自動的に期限切れにし、再利用を強制してノードを最新の状態に保ちます。
- **ドリフト**: Karpenter は設定の変更（`NodePool` や `NodeClass` など）を検出し、必要な変更を適用します
- **統合**: コストを効率的に運用するための重要な機能として、Karpenter はクラスターのコンピュートを継続的に最適化します。例えば、ワークロードが使用率の低いコンピュートインスタンスで実行されている場合、より少ないインスタンスに統合します。

ディスラプションは、`NodePool` の `disruption` ブロックを通じて設定されます。以下は、Auto Mode が設定した `general-purpose` NodePool 設定ポリシーの一部です。

```json
  disruption:
    budgets:
    - nodes: 10%
    consolidateAfter: 30s
    consolidationPolicy: WhenEmptyOrUnderutilized
```

1. `budget` はカスタム値に設定されており、ワークロードへの悪影響を最小限に抑えるため、同時にディスラプションされるノードの割合を指定します。
2. `consolidateAfter` は統合プロセスを開始する前の待機時間を指定します。
3. `WhenEmptyOrUnderutilized` ポリシーにより、Karpenter はノードが空または使用率が低い場合にノードを置き換えることができます。

次のコマンドを使用して NodePool 設定を確認し、ディスラプション設定を確認できます。

```bash
$ kubectl get nodepools general-purpose -o yaml | yq .spec.disruption
```

`consolidationPolicy` の値 `WhenEmptyOrUnderutilized` は、`consolidateAfter`（ここでは30秒）後にパッキングを最適化するためにノードを統合し、一度に10%のノードの置き換えを許可する予算を持ちます。他の値も可能で、例えば `consolidationPolicy` は `WhenEmpty` に設定することもでき、これはワークロード Pod を含まないノードのみにディスラプションを制限します。ディスラプションの詳細については、[Karpenter ドキュメント](https://karpenter.sh/docs/concepts/disruption/#consolidation)をご覧ください。

インフラストラクチャのスケールアウトは、コスト効率的にコンピュートインフラストラクチャを運用するための方程式の片面に過ぎません。例えば、使用率の低いコンピュートインスタンスで実行されているワークロードをより少ないインスタンスにコンパクトにするなど、継続的に最適化できる必要もあります。これにより、コンピュート上でワークロードを実行する全体的な効率が向上し、オーバーヘッドが減少し、コストが削減されます。

`disruption` が `consolidationPolicy: WhenEmptyOrUnderutilized` に設定されている場合の自動統合のトリガー方法を見ていきましょう:

1. `inflate` ワークロードを5から12レプリカにスケールし、Karpenter に追加容量をプロビジョニングさせる
2. ワークロードを5レプリカに戻してスケールダウンする
3. Karpenter がコンピュートを統合するのを観察する

`inflate` ワークロードを再度スケールして、より多くのリソースを消費させます:

```bash timeout=240
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

これにより、このデプロイメントの合計メモリ要求が約12Giに変更されます。各ノードの kubelet 用に予約されている約600Miを考慮すると、これは `m5.large` タイプの2つのインスタンスに収まります:

```bash
$ kubectl get nodes -L beta.kubernetes.io/instance-type -L kubernetes.io/arch -L kubernetes.io/os --sort-by=.metadata.creationTimestamp
NAME                  STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   20h     v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0e209b70f1d2dfae0   Ready    <none>   17h     v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   90m     v1.33.4-eks-e386d34   m5a.large       amd64   linux
i-076a7c45e5f8e5f11   Ready    <none>   7m12s   v1.33.4-eks-e386d34   m5a.large       amd64   linux
```

次に、レプリカ数を5に戻してスケールダウンします:

```bash wait=90
$ kubectl scale -n other deployment/inflate --replicas 5
```

Karpenter イベントを確認して、デプロイメントのスケールに応じて Karpenter がどのようなアクションを取ったかを把握できます。次のコマンドを実行する前に約5〜10秒待ちます:

```bash hook=grep
$ kubectl events | grep -i 'disruption'

3m39s       Normal    DisruptionBlocked                nodeclaim/general-purpose-5c74h   Node is nominated for a pending pod
3m42s       Normal    DisruptionLaunching              nodeclaim/general-purpose-l6dpl   Launching NodeClaim: Underutilized
3m42s       Normal    DisruptionWaitingReadiness       nodeclaim/general-purpose-l6dpl   Waiting on readiness to continue disruption
3m39s       Normal    DisruptionBlocked                nodeclaim/general-purpose-l6dpl   Nodeclaim does not have an associated node
18m         Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Nodeclaim does not have an associated node
4m38s       Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Node is nominated for a pending pod
3m20s       Normal    DisruptionTerminating            nodeclaim/general-purpose-m6gjm   Disrupting NodeClaim: Underutilized
2m29s       Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Node is deleting or marked for deletion
4m38s       Normal    DisruptionTerminating            nodeclaim/general-purpose-nhtc7   Disrupting NodeClaim: Underutilized
4m28s       Normal    DisruptionBlocked                nodeclaim/general-purpose-nhtc7   Node is deleting or marked for deletion
4m38s       Normal    DisruptionBlocked                node/i-076a7c45e5f8e5f11          Node is nominated for a pending pod
3m20s       Normal    DisruptionTerminating            node/i-076a7c45e5f8e5f11          Disrupting Node: Underutilized
2m29s       Normal    DisruptionBlocked                node/i-076a7c45e5f8e5f11          Node is deleting or marked for deletion
3m39s       Normal    DisruptionBlocked                node/i-0a78dba9f62f5e0e4          Node is nominated for a pending pod
3m19s       Normal    DisruptionBlocked                node/i-0e1f072dc32194cc7          Node is nominated for a pending pod
4m38s       Normal    DisruptionTerminating            node/i-0e209b70f1d2dfae0          Disrupting Node: Underutilized
4m28s       Normal    DisruptionBlocked                node/i-0e209b70f1d2dfae0          Node is deleting or marked for deletion
```

出力には、Karpenter が特定のノードを識別して cordon、drain、そして終了させる様子が表示されます:

これにより、Kubernetes スケジューラーはそれらのノード上の Pod を残りの容量に配置し、クラスター内のノード数が減少したことが確認できます。

```bash
$ kubectl get nodes -L beta.kubernetes.io/instance-type -L kubernetes.io/arch -L kubernetes.io/os --sort-by=.metadata.creationTimestamp

NAME                  STATUS   ROLES    AGE    VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   21h    v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   104m   v1.33.4-eks-e386d34   m5a.large       amd64   linux
i-0e1f072dc32194cc7   Ready    <none>   6m4s   v1.33.4-eks-e386d34   c6a.large       amd64   linux
```

Karpenter は、ワークロードの変更に応じてノードをより安価なバリアントに置き換えられる場合、さらに統合することもできます。これは、`inflate` デプロイメントのレプリカを1にスケールダウンすることで実証できます。合計メモリ要求は約1Giになります:

```bash wait=60
$ kubectl scale -n other deployment/inflate --replicas 1
```

Karpenter ログを確認して、コントローラーがどのようなアクションを取ったかを確認できます:

```bash test=false
$ kubectl events | grep -i 'disruption'
```

出力には、Karpenter が使用率の低いノードを削除して NodePool 内のワークロードを統合する様子が表示されます。

これで EKS Auto Mode のオートスケーリング機能の紹介は終わりです。Auto Mode が提供するデフォルトの NodePool と NodeClass 設定を使用しましたが、特定のニーズに合わせてクラスター内にカスタムの NodePool と NodeClass リソースを設定することもできます。

