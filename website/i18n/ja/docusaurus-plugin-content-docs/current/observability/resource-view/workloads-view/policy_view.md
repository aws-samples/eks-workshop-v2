---
title: "Policy"
sidebar_position: 60
tmdTranslationSourceHash: 9771f0143ec84a1bc572481a9b92f750
---

[ポリシー](https://kubernetes.io/docs/concepts/policy/)はクラスターリソースの使用量を定義し、推奨されるベストプラクティスを満たすために _Kubernetes Objects_ のデプロイメントを制限します。以下は、**_Resource Types_** - **_Policy_** セクションでクラスターレベルで表示できる異なるタイプのポリシーです：

- Limit Ranges
- Resource Quotas
- Network Policies
- Pod Disruption Budgets
- Pod Security Policies

[LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/) は、名前空間内の各オブジェクトの種類（Pod や PersistentVolumeClaim など）に指定されたリソース割り当て（limits と requests）を制限するポリシーです。_リソース割り当て_ は、必要なリソースを指定すると同時に、オブジェクトがリソースを過剰に消費しないようにするために使用されます。_Karpenter_ は、アプリケーションの需要に基づいて適切なサイズのリソースをデプロイするのに役立つ Kubernetes のオートスケーラーです。EKS クラスターで _オートスケーリング_ を設定するには、[Karpenter](../../../fundamentals/compute/karpenter/index.md) セクションを参照してください。

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/) は、名前空間レベルで定義されたハードリミットであり、`pods`、`services`、`cpu`、`memory` などのコンピューティングリソースなどのオブジェクトは、ResourceQuota オブジェクトによって定義されたハードリミット内で作成される必要があり、そうでない場合は拒否されます。

[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) は、ソースと宛先間の通信を確立します。例えば、Pod の `ingress` と `egress` はネットワークポリシーを使用して制御されます。

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) は、削除、更新、Pod の削除などの Pod に発生する可能性のある中断を軽減する方法です。Pod に発生する可能性のある _[中断](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_ のタイプについての詳細情報。

次のスクリーンショットは、名前空間ごとの _PodDisruptionBudgets_ のリストを表示しています。

![Insights](/img/resource-view/policy-poddisruption.jpg)

_karpenter_ の _Pod Disruption Budget_ を調べてみましょう。名前空間やこの _Pod Disruption Budget_ に一致する必要があるパラメータなど、このリソースの詳細を確認できます。下のスクリーンショットでは、`max unavailable = 1` が設定されており、これは利用不可能な _karpenter_ Pod の最大数が 1 であることを意味します。

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)
