---
title: Pod Affinity と Anti-Affinity
sidebar_position: 30
tmdTranslationSourceHash: 439beab5149c47c5e73f707f562b78c3
---

Podは特定のノードや特定の状況下で実行されるよう制約をかけることができます。これには、ノードごとに1つのアプリケーションPodのみを実行したい場合や、複数のPodをノード上でペアリングしたい場合などが含まれます。さらに、ノードアフィニティを使用する場合、Podには優先的または必須の制約を設定できます。

このレッスンでは、`checkout-redis` Podをノードごとに1つのインスタンスのみ実行するようにし、`checkout` Podを`checkout-redis` Podが存在するノードにのみ1つのインスタンスを実行するように、Pod間のアフィニティとアンチアフィニティに焦点を当てます。これにより、キャッシングPod（`checkout-redis`）が最高のパフォーマンスを得るために`checkout` Podインスタンスとローカルで実行されるようになります。

まず最初に、`checkout`と`checkout-redis` Podが実行されていることを確認しましょう：

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-vzkzw         1/1     Running   0          125m
checkout-redis-6cfd7d8787-kxs8r   1/1     Running   0          127m
```

両方のアプリケーションがクラスター内で1つのPodを実行していることがわかります。次に、それらがどこで実行されているかを確認しましょう：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-698856df4d-vzkzw       ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

上記の結果から、`checkout-698856df4d-vzkzw` Podは`ip-10-42-11-142.us-west-2.compute.internal`ノードで実行され、`checkout-redis-6cfd7d8787-kxs8r` Podは`ip-10-42-10-225.us-west-2.compute.internal`ノードで実行されていることがわかります。

:::note
あなたの環境では、最初にPodが同じノード上で実行されている場合があります
:::

**checkout**デプロイメントに`podAffinity`と`podAntiAffinity`ポリシーを設定して、ノードごとに1つの`checkout` Podが実行され、`checkout-redis` Podが既に実行されているノードでのみ実行されるようにしましょう。優先的な動作ではなく要件とするために`requiredDuringSchedulingIgnoredDuringExecution`を使用します。

次のKustomizationは**checkout**デプロイメントに**podAffinity**と**podAntiAffinity**ポリシーの両方を指定した`affinity`セクションを追加します：

```kustomization
modules/fundamentals/affinity/checkout/checkout.yaml
Deployment/checkout
```

上記のマニフェストでは、`podAffinity`セクションが次のことを保証します：

- CheckoutのPodはRedisのPodが実行されているノードでのみスケジュールされます。
- これは`app.kubernetes.io/component: redis`というラベルを持つPodとマッチングすることで実施されます。
- `topologyKey: kubernetes.io/hostname`はこのルールがノードレベルで適用されることを保証します。

`podAntiAffinity`セクションは次のことを保証します：

- ノードごとに1つのcheckout Podのみが実行されます。
- これは`app.kubernetes.io/component: service`と`app.kubernetes.io/instance: checkout`のラベルを持つPodが同じノード上で実行されないようにすることで実現されます。

変更を適用するために、次のコマンドを実行してクラスター内の**checkout**デプロイメントを変更します：

```bash
$ kubectl delete -n checkout deployment checkout
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/affinity/checkout/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
$ kubectl rollout status deployment/checkout \
  -n checkout --timeout 180s
```

**podAffinity**セクションは、`checkout-redis` Podが既にノード上で実行されていることを保証します - これは`checkout` Podが正しく実行されるために`checkout-redis`を必要とすると仮定できるからです。**podAntiAffinity**セクションは、**`app.kubernetes.io/component=service`**ラベルと一致するノード上に既に`checkout` Podが実行されていないことを要求します。では、デプロイメントをスケールアップして設定が機能しているか確認しましょう：

```bash
$ kubectl scale -n checkout deployment/checkout --replicas 2
```

各Podがどこで実行されているか検証します：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-6c7c9cdf4f-p5p6q       ip-10-42-10-120.us-west-2.compute.internal
checkout-6c7c9cdf4f-wwkm4
checkout-redis-6cfd7d8787-gw59j ip-10-42-10-120.us-west-2.compute.internal
```

この例では、最初の`checkout` Podは既存の`checkout-redis` Podと同じノード上で実行されており、設定した**podAffinity**ルールを満たしています。2番目のPodはまだPending状態です。これは、私たちが定義した**podAntiAffinity**ルールにより、同じノード上で2つの`checkout` Podを起動できないためです。2番目のノードには`checkout-redis` Podが実行されていないため、Pendingのままです。

次に、私たちの2つのノード用に`checkout-redis`を2つのインスタンスにスケールしますが、最初に`checkout-redis`デプロイメントポリシーを変更して、`checkout-redis`インスタンスが各ノードに分散されるようにしましょう。これを行うには、**podAntiAffinity**ルールを作成するだけです。

```kustomization
modules/fundamentals/affinity/checkout-redis/checkout-redis.yaml
Deployment/checkout-redis
```

上記のマニフェストでは、`podAntiAffinity`セクションが次のことを保証します：

- RedisのPodは異なるノードに分散されます。
- これは`app.kubernetes.io/component: redis`というラベルを持つ複数のPodが同じノード上で実行されないようにすることで実施されます。
- `topologyKey: kubernetes.io/hostname`はこのルールがノードレベルで適用されることを保証します。

次のコマンドでそれを適用します：

```bash
$ kubectl delete -n checkout deployment checkout-redis
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/affinity/checkout-redis/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout unchanged
deployment.apps/checkout-redis configured
$ kubectl rollout status deployment/checkout-redis \
  -n checkout --timeout 180s
```

**podAntiAffinity**セクションは、**`app.kubernetes.io/component=redis`**ラベルと一致するノード上に既に`checkout-redis` Podが実行されていないことを要求します。

```bash
$ kubectl scale -n checkout deployment/checkout-redis --replicas 2
```

実行中のPodを確認して、それぞれ2つずつ実行されていることを検証します：

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-6ddwn        1/1     Running   0          4m14s
checkout-5b68c8cddf-rd7xf        1/1     Running   0          4m12s
checkout-redis-7979df659-cjfbf   1/1     Running   0          19s
checkout-redis-7979df659-pc6m9   1/1     Running   0          22s
```

また、Podがどこで実行されているかを確認し、**podAffinity**と**podAntiAffinity**ポリシーが守られていることを確認することもできます：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-7979df659-57xcb  ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-7979df659-r7kkm  ip-10-42-12-31.us-west-2.compute.internal
```

Podのスケジューリングは問題なさそうですが、`checkout` Podをさらにスケールして、3つ目のPodがどこにデプロイされるかを確認することで、さらに検証できます：

```bash
$ kubectl scale --replicas=3 deployment/checkout --namespace checkout
```

実行中のPodを確認すると、3つ目の`checkout` Podは、すでに2つのノードにPodがデプロイされており、3つ目のノードには`checkout-redis` Podが実行されていないため、Pending状態になっていることがわかります。

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-bn8bp        1/1     Running   0          4m59s
checkout-5b68c8cddf-clnps        1/1     Running   0          6m9s
checkout-5b68c8cddf-lb69n        0/1     Pending   0          6s
checkout-redis-7979df659-57xcb   1/1     Running   0          35s
checkout-redis-7979df659-r7kkm   1/1     Running   0          2m10s
```

Pending状態のPodを削除してこのセクションを終了しましょう：

```bash
$ kubectl scale --replicas=2 deployment/checkout --namespace checkout
```
