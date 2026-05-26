---
title: その他のコンポーネント
sidebar_position: 50
pagination_next: null
tmdTranslationSourceHash: 50d648c69e8d1ee1c8a365c24b4097c3
---

このラボ演習では、Kustomizeの力を活用してサンプルアプリケーションの残りの部分を効率的にデプロイします。次のkustomizationファイルは、他のkustomizationを参照して複数のコンポーネントを一緒にデプロイする方法を示しています：

```file
manifests/base-application/kustomization.yaml
```

:::tip
Catalog APIがこのkustomizationに含まれていることに注目してください。既にデプロイしたのではないでしょうか？

KubernetesはDeclareativeなメカニズムを使用しているため、Catalog APIのマニフェストを再度適用でき、すべてのリソースが既に作成されているためKubernetesはアクションを実行しないことを期待できます。
:::

このkustomizationをクラスターに適用して、残りのコンポーネントをデプロイします：

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

:::info
追加のワークロードをデプロイすると、EKS Auto Modeは新しいPodを収容するために必要に応じて追加のコンピュートインスタンスを自動的にプロビジョニングします。
:::

EKS Auto Modeがワークロード用にノードをプロビジョニングする様子を確認してください。EKS Auto Modeがアプリケーション用にgeneral-purposeノードプールに2つ目のノードをプロビジョニングする様子が表示されます。また、Podを移動する容量があるため、systemノードも統合されます。

```bash timeout=180 test=false
$ kubectl get nodes --watch
...
NAME                  STATUS     ROLES    AGE   VERSION
i-082b0e8be0994671a   NotReady   <none>   1s    v1.33.4-eks-e386d34
...
i-082b0e8be0994671a   Ready      <none>   2s    v1.33.4-eks-e386d34
```

前のコマンドを実行するタイミングによっては、`NotReady`または`Ready`ステータスのノードが表示される場合があります。ただし、いずれの場合でも、最も新しいAgeを持つ新しいノードが表示されるはずです。ノードが表示されたら、`Ctrl+C`を押してウォッチを停止してください。Podは実行中になります：

Kubernetesはさまざまな目的でラベルを使用します。たとえば、ノードにはNodePoolを示すラベルがあり、次のコマンドで確認できます：
```bash
$ kubectl get nodes -o json | jq -c '.items[] | {name: .metadata.name, nodepool: .metadata.labels."karpenter.sh/nodepool"}'
{"name":"i-082b0e8be0994671a","nodepool":"general-purpose"}
{"name":"i-0af75b7f0f828f36c","nodepool":"general-purpose"}
```


これが完了したら、`kubectl wait`を使用して、続行する前にすべてのコンポーネントが起動していることを確認できます：

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

これで、各アプリケーションコンポーネント用のNamespaceが作成されます：

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
ui         Active   62s
```

コンポーネント用に作成されたすべてのリソースも確認できます：

```bash
$ kubectl get all -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                                  READY   STATUS    RESTARTS      AGE
carts       pod/carts-68d496fff8-h2w84            1/1     Running   1 (75s ago)   89s
carts       pod/carts-dynamodb-995f7768c-s6wv2    1/1     Running   0             89s
catalog     pod/catalog-5fdcc8c65-rrcbh           1/1     Running   3 (68s ago)   89s
catalog     pod/catalog-mysql-0                   1/1     Running   0             88s
checkout    pod/checkout-5b885fb57c-8bkf2         1/1     Running   0             89s
checkout    pod/checkout-redis-69cb79ff4d-vxjlh   1/1     Running   0             89s
orders      pod/orders-74f89d6dbd-pw58j           1/1     Running   0             88s
orders      pod/orders-postgresql-0               1/1     Running   0             88s
ui          pod/ui-5989474687-tqps9               1/1     Running   0             88s

NAMESPACE   NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
carts       service/carts               ClusterIP   172.20.64.186    <none>        80/TCP     89s
carts       service/carts-dynamodb      ClusterIP   172.20.187.59    <none>        8000/TCP   89s
catalog     service/catalog             ClusterIP   172.20.242.75    <none>        80/TCP     89s
catalog     service/catalog-mysql       ClusterIP   172.20.4.209     <none>        3306/TCP   89s
...
```

サンプルアプリケーションがデプロイされ、このワークショップの残りのラボで使用する基盤を提供する準備が整いました！

## 次のステップ

サンプルアプリケーションをデプロイしたので、学習の旅を定義するために2つのオプションのいずれかを選択してください。

<div style={{display: 'flex', gap: '2rem', marginTop: '2rem', flexWrap: 'wrap'}}>
  <a href="../developer" style={{textDecoration: 'none', color: 'inherit', flex: '1', minWidth: '280px', maxWidth: '400px'}}>
    <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', height: '100%', cursor: 'pointer'}}>
      <h3 style={{marginTop: 0}}>Developer Essentials</h3>
      <p>コンテナ化されたアプリケーションのデプロイと管理に不可欠なEKS機能を学びます。</p>
    </div>
  </a>
    <a href="../operator" style={{textDecoration: 'none', color: 'inherit', flex: '1', minWidth: '280px', maxWidth: '400px'}}>
    <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', height: '100%', cursor: 'pointer'}}>
      <h3 style={{marginTop: 0}}>Operator Essentials</h3>
      <p>コンテナプラットフォームの管理に不可欠なEKS機能を学びます。</p>
    </div>
  </a>
</div>

