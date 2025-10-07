---
title: "Policy"
sidebar_position: 60
kiteTranslationSourceHash: fb9f771b65c38f4d06d22d91ef2991af
---

[ポリシー](https://kubernetes.io/docs/concepts/policy/)はクラスターリソースの使用量を定義し、推奨されるベストプラクティスを満たすために_Kubernetes オブジェクト_のデプロイメントを制限します。クラスターレベルの**_Resource Types_** - **_Policy_**セクションで表示できる異なるタイプのポリシーは以下の通りです：

- Limit Ranges
- Resource Quotas
- Network Policies
- Pod Disruption Budgets
- Pod Security Policies

[LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)は、名前空間内の各オブジェクトの種類（PodやPersistentVolumeClaimなど）に対して指定されたリソース割り当て（制限とリクエスト）を制限するポリシーです。_リソース割り当て_は、必要なリソースを指定し、同時にオブジェクトがリソースを過剰に消費しないようにするために使用されます。_Karpenter_は、アプリケーションの需要に基づいて適切なサイズのリソースをデプロイするのに役立つKubernetesのオートスケーラーです。EKSクラスターで_オートスケーリング_を設定するには、[Karpenter](../../../autoscaling/compute/karpenter/index.md)セクションを参照してください。

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)は、名前空間レベルで定義されたハードリミットであり、`pods`や`services`、`cpu`や`memory`などのコンピューティングリソースのようなオブジェクトは、ResourceQuotaオブジェクトによって定義されたハードリミット内で作成される必要があり、そうでない場合は拒否されます。

[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)は、ソースと宛先間の通信を確立します。例えば、ポッドの`ingress`と`egress`はネットワークポリシーを使用して制御されます。

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)は、削除、デプロイメントの更新、ポッドの削除などのポッドに発生する可能性のある中断を軽減する方法です。ポッドに発生する可能性のある_[中断](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_のタイプについての詳細情報。

次のスクリーンショットは、名前空間ごとの_PodDisruptionBudgets_のリストを表示しています。

![Insights](/img/resource-view/policy-poddisruption.jpg)

_karpenter_の_Pod Disruption Budget_を調べてみましょう。この_Pod Disruption Budget_の名前空間やこの_Pod Disruption Budget_に一致する必要があるパラメータなどのリソースの詳細を確認できます。下のスクリーンショットでは、`max unavailable = 1`が設定されており、これは利用不可能な_karpenter_ポッドの最大数が1であることを意味します。

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)

