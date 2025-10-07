---
title: ポッドアフィニティとアンチアフィニティ
sidebar_position: 30
kiteTranslationSourceHash: 439beab5149c47c5e73f707f562b78c3
---

ポッドは、特定のノードや特定の状況下で実行するように制約を設けることができます。これには、ノードごとに1つのアプリケーションポッドのみを実行したい場合や、ポッドをノード上でペアにしたい場合などが含まれます。さらに、ノードアフィニティを使用する場合、ポッドには優先または必須の制約を設けることができます。

このレッスンでは、ノードごとに`checkout-redis`ポッドのインスタンスを1つだけ実行し、`checkout-redis`ポッドが存在するノードでのみ`checkout`ポッドを実行するように、ポッド間のアフィニティとアンチアフィニティに焦点を当てます。これにより、キャッシングポッド（`checkout-redis`）が最高のパフォーマンスを得るために`checkout`ポッドのインスタンスとローカルで実行されることが保証されます。

最初に、`checkout`と`checkout-redis`ポッドが実行されていることを確認しましょう：

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-vzkzw         1/1     Running   0          125m
checkout-redis-6cfd7d8787-kxs8r   1/1     Running   0          127m
```

両方のアプリケーションがクラスターで1つのポッドを実行していることがわかります。次に、それらがどこで実行されているかを確認しましょう：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-698856df4d-vzkzw       ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

上記の結果に基づくと、`checkout-698856df4d-vzkzw`ポッドは`ip-10-42-11-142.us-west-2.compute.internal`ノードで実行され、`checkout-redis-6cfd7d8787-kxs8r`ポッドは`ip-10-42-10-225.us-west-2.compute.internal`ノードで実行されています。

:::note
環境によっては、最初にポッドが同じノードで実行されている場合があります
:::

**checkout**デプロイメントに`podAffinity`と`podAntiAffinity`ポリシーを設定して、ノードごとに`checkout`ポッドが1つ実行され、`checkout-redis`ポッドがすでに実行されているノードでのみ実行されるようにしましょう。この要件を優先的な振る舞いではなく必須にするために、`requiredDuringSchedulingIgnoredDuringExecution`を使用します。

次のカスタマイゼーションは、**checkout**デプロイメントに**podAffinity**と**podAntiAffinity**ポリシーの両方を指定する`affinity`セクションを追加します：

```kustomization
modules/fundamentals/affinity/checkout/checkout.yaml
Deployment/checkout
```
上記のマニフェストでは、`podAffinity`セクションが以下を保証します：
   - Checkoutポッドは、Redisポッドが実行されているノードでのみスケジュールされます。
   - これは、ラベル`app.kubernetes.io/component: redis`を持つポッドをマッチングすることで適用されます。
   - `topologyKey: kubernetes.io/hostname`により、このルールはノードレベルで適用されます。

`podAntiAffinity`セクションは以下を保証します：
   - ノードごとに1つのCheckoutポッドのみが実行されます。
   - これは、ラベル`app.kubernetes.io/component: service`および`app.kubernetes.io/instance: checkout`を持つポッドが同じノードで実行されるのを防ぐことで達成されます。

この変更を適用するために、以下のコマンドを実行して、クラスター内の**checkout**デプロイメントを変更します：

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

**podAffinity**セクションは、`checkout-redis`ポッドがすでにノードで実行されていることを保証します — これは、`checkout`ポッドが正しく実行するために`checkout-redis`を必要とすると想定できるためです。**podAntiAffinity**セクションは、**`app.kubernetes.io/component=service`**ラベルをマッチングすることで、ノードですでに`checkout`ポッドが実行されていないことを要求します。では、デプロイメントをスケールアップして構成が機能しているかを確認しましょう：

```bash
$ kubectl scale -n checkout deployment/checkout --replicas 2
```

各ポッドがどこで実行されているかを検証します：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-6c7c9cdf4f-p5p6q       ip-10-42-10-120.us-west-2.compute.internal
checkout-6c7c9cdf4f-wwkm4
checkout-redis-6cfd7d8787-gw59j ip-10-42-10-120.us-west-2.compute.internal
```

この例では、最初の`checkout`ポッドは既存の`checkout-redis`ポッドと同じノードで実行されており、設定した**podAffinity**ルールを満たしています。2番目のポッドはまだペンディング状態です。これは、定義した**podAntiAffinity**ルールが2つの`checkout`ポッドが同じノードで開始されることを許可していないからです。2番目のノードには`checkout-redis`ポッドが実行されていないため、ペンディング状態のままとなります。

次に、2つのノード用に`checkout-redis`を2つのインスタンスにスケールしますが、まず`checkout-redis`デプロイメントポリシーを変更して、`checkout-redis`インスタンスを各ノードに分散させましょう。これを行うには、単に**podAntiAffinity**ルールを作成する必要があります。

```kustomization
modules/fundamentals/affinity/checkout-redis/checkout-redis.yaml
Deployment/checkout-redis
```
上記のマニフェストでは、`podAntiAffinity`セクションが以下を保証します：
   - Redisポッドは異なるノードに分散されます。
   - これは、ラベル`app.kubernetes.io/component: redis`を持つ複数のポッドが同じノードで実行されるのを防ぐことで適用されます。
   - `topologyKey: kubernetes.io/hostname`により、このルールはノードレベルで適用されます。

以下のコマンドでそれを適用します：

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

**podAntiAffinity**セクションは、**`app.kubernetes.io/component=redis`**ラベルをマッチングすることで、ノードですでに`checkout-redis`ポッドが実行されていないことを要求します。

```bash
$ kubectl scale -n checkout deployment/checkout-redis --replicas 2
```

実行中のポッドを確認して、それぞれ2つずつ実行されていることを確認します：

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-6ddwn        1/1     Running   0          4m14s
checkout-5b68c8cddf-rd7xf        1/1     Running   0          4m12s
checkout-redis-7979df659-cjfbf   1/1     Running   0          19s
checkout-redis-7979df659-pc6m9   1/1     Running   0          22s
```

また、ポッドがどこで実行されているかを確認して、**podAffinity**と**podAntiAffinity**ポリシーが守られていることを確認できます：

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-7979df659-57xcb  ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-7979df659-r7kkm  ip-10-42-12-31.us-west-2.compute.internal
```

ポッドのスケジューリングは順調ですが、`checkout`ポッドをさらにスケールして3番目のポッドがどこに展開されるかを確認しましょう：

```bash
$ kubectl scale --replicas=3 deployment/checkout --namespace checkout
```

実行中のポッドを確認すると、2つのノードにはすでにポッドがデプロイされており、3番目のノードには`checkout-redis`ポッドが実行されていないため、3番目の`checkout`ポッドはPending状態になっていることがわかります。

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-bn8bp        1/1     Running   0          4m59s
checkout-5b68c8cddf-clnps        1/1     Running   0          6m9s
checkout-5b68c8cddf-lb69n        0/1     Pending   0          6s
checkout-redis-7979df659-57xcb   1/1     Running   0          35s
checkout-redis-7979df659-r7kkm   1/1     Running   0          2m10s
```

このセクションを終了するために、Pendingポッドを削除しましょう：

```bash
$ kubectl scale --replicas=2 deployment/checkout --namespace checkout
```
