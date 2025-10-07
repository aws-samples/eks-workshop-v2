---
title: ワークロードのスケーリング
sidebar_position: 30
kiteTranslationSourceHash: 6c2730f893e1af352a91566144abe7b7
---

Fargateのもう一つの利点は、簡素化された水平スケーリングモデルです。EC2をコンピュートとして使用する場合、Podのスケーリングでは、Podだけでなく基盤となるコンピュートがどのようにスケールするかも考慮する必要があります。Fargateは基盤となるコンピュートを抽象化するため、Pod自体のスケーリングのみを考慮すればよいのです。

これまで見てきた例では、単一のPodレプリカのみを使用していました。実際のシナリオで一般的に想定されるように、これを水平方向にスケールするとどうなるでしょうか？`checkout`サービスをスケールアップして確認してみましょう：

```kustomization
modules/fundamentals/fargate/scaling/deployment.yaml
Deployment/checkout
```

Kustomizationを適用し、ロールアウトが完了するまで待ちます：

```bash timeout=240
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/scaling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

ロールアウトが完了したら、Podの数を確認できます：

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-2c75m   1/1     Running   0          2m12s
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

これらのPodはそれぞれ別々のFargateインスタンスにスケジュールされています。以前と同様のステップに従って、特定のPodのノードを識別することでこれを確認できます。

