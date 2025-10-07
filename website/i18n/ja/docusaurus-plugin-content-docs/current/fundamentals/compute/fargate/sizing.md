---
title: リソース割り当て
sidebar_position: 20
kiteTranslationSourceHash: 5fc8ef93035d670c6eb30eb4380101ec
---

[Fargate の料金](https://aws.amazon.com/fargate/pricing/)の主な要素は CPU とメモリに基づいており、Fargate インスタンスに割り当てられるリソース量は Pod で指定されるリソースリクエストに依存します。Fargate には[ドキュメント化された](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory)有効な CPU とメモリの組み合わせがあり、ワークロードが Fargate に適しているかを評価する際に考慮する必要があります。

前回のデプロイメントで Pod に割り当てられたリソースを、そのアノテーションを調べることで確認できます：

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "0.25vCPU 0.5GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

この例（上記）では、`CapacityProvisioned` アノテーションが 0.25 vCPU と 0.5 GB のメモリが割り当てられていることを示しています。これは Fargate インスタンスの最小サイズです。しかし、Pod がより多くのリソースを必要とする場合はどうなるでしょうか？幸いなことに、Fargate はリソースリクエストに応じて様々なオプションを提供しており、試してみることができます。

次の例では、`checkout` コンポーネントがリクエストするリソース量を 1 vCPU と 2.5G のメモリに増やし、Fargate スケジューラがどのように適応するかを見てみましょう：

```kustomization
modules/fundamentals/fargate/sizing/deployment.yaml
Deployment/checkout
```

kustomization を適用し、ロールアウトが完了するまで待ちます：

```bash timeout=220
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/sizing
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

では、Fargate によって割り当てられたリソースを再度確認しましょう。上記の変更に基づいて、何が表示されると予想しますか？

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "1vCPU 3GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

Pod によってリクエストされたリソースは、上記で説明された有効な組み合わせセットの中で、最も近い Fargate 構成に切り上げられています。
