---
title: 他のコンポーネント
sidebar_position: 50
tmdTranslationSourceHash: 2b121f2c62f5ef803e4d6ed1ed186a8c
---

この実習では、Kustomizeのパワーを活用してサンプルアプリケーションの残りの部分を効率的にデプロイします。次のkustomizationファイルは、他のkustomizationを参照して複数のコンポーネントを一緒にデプロイする方法を示しています：

```file
manifests/base-application/kustomization.yaml
```

:::tip
カタログAPIがこのkustomizationに含まれていることに気付きましたか？既にデプロイしましたよね？

Kubernetesは宣言的なメカニズムを使用しているため、カタログAPIのマニフェストを再度適用しても、すべてのリソースが既に作成されているため、Kubernetesは何のアクションも取りません。
:::

このkustomizationをクラスタに適用して、残りのコンポーネントをデプロイしましょう：

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

これが完了したら、`kubectl wait`を使用して、進む前にすべてのコンポーネントが起動していることを確認できます：

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

これで、各アプリケーションコンポーネント用の名前空間ができました：

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

また、コンポーネント用に作成されたすべてのDeploymentも確認できます：

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                READY   UP-TO-DATE   AVAILABLE   AGE
carts       carts               1/1     1            1           90s
carts       carts-dynamodb      1/1     1            1           90s
catalog     catalog             1/1     1            1           7m46s
checkout    checkout            1/1     1            1           90s
checkout    checkout-redis      1/1     1            1           90s
orders      orders              1/1     1            1           90s
orders      orders-postgresql   1/1     1            1           90s
ui          ui                  1/1     1            1           90s
```

サンプルアプリケーションがデプロイされ、このワークショップの残りのラボで使用する基盤として準備が整いました！

:::tip
Kustomizeについてもっと理解したい場合は、このワークショップで提供されている[オプションモジュール](../kustomize/index.md)をご覧ください。
:::
