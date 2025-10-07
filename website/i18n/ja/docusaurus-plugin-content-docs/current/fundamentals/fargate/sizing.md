---
title: リソース割り当て
sidebar_position: 20
kiteTranslationSourceHash: 5fc8ef93035d670c6eb30eb4380101ec
---

[Fargateの料金](https://aws.amazon.com/fargate/pricing/)の主な計算要素はCPUとメモリに基づいており、Fargateインスタンスに割り当てられるリソースの量はPodで指定されたリソースリクエストに依存します。Fargateには[文書化された](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory)有効なCPUとメモリの組み合わせのセットがあり、ワークロードがFargateに適しているかどうかを評価する際に考慮すべきです。

前回のデプロイメントから私たちのPodに対してどのリソースがプロビジョニングされたかを、アノテーションを調べることで確認できます：

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

この例では（上記）、`CapacityProvisioned`アノテーションから、0.25 vCPUと0.5 GBのメモリが割り当てられていることがわかります。これは最小のFargateインスタンスサイズです。しかし、もしPodがより多くのリソースを必要とする場合はどうでしょうか？幸いなことに、Fargateはリソースリクエストに応じて様々なオプションを提供しており、それを試すことができます。

次の例では、`checkout`コンポーネントがリクエストするリソース量を1 vCPUと2.5 GBのメモリに増やし、Fargateスケジューラーがどのように適応するかを確認します：

```kustomization
modules/fundamentals/fargate/sizing/deployment.yaml
Deployment/checkout
```

kustomizationを適用し、ロールアウトが完了するのを待ちます：

```bash timeout=220
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/sizing
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

では、Fargateによって割り当てられたリソースを再度確認してみましょう。上記の変更に基づいて、何が表示されると予想しますか？

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

Podがリクエストしたリソースは、前述の有効な組み合わせセットで概説されている最も近いFargate構成に切り上げられています。

