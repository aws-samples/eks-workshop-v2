---
title: "仕組み"
sidebar_position: 30
kiteTranslationSourceHash: 94ac3fa1cc182af13143ffc3e7df7f71
---

Kubernetesでは、他のPodに対する相対的な優先度をPodに割り当てることができます。Kubernetesスケジューラはこれらの優先度を使用して、より優先度の高いPodを収容するために優先度の低いPodを先取りします。これは`PriorityClass`リソースを通じて実現され、Podに割り当てることができる優先度値を定義します。さらに、デフォルトの`PriorityClass`をネームスペースに割り当てることができます。

以下は、他のPodよりも比較的高い優先度をPodに与える優先度クラスの例です：

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority Pods only."
```

そして、上記の優先度クラスを使用したPod仕様の例です：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
    - name: nginx
      image: nginx
      imagePullPolicy: IfNotPresent
  priorityClassName: high-priority # Priority Class specified
```

これがどのように機能するかについての詳細な説明は、Kubernetesのドキュメント「[Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/)」を参照してください。

EKSクラスターでのコンピュートのオーバープロビジョニングにこの概念を適用するには、次の手順を実行します：

1. 優先度値「**-1**」を持つ優先度クラスを作成し、空の[Pause Container](https://www.ianlewis.org/en/almighty-pause-container)に割り当てます。これらの空の「pause」コンテナはプレースホルダーとして機能します。

2. 優先度値「**0**」を持つデフォルトの優先度クラスを作成します。これはクラスター全体にグローバルに割り当てられるため、優先度クラスが指定されていない任意のデプロイメントにはこのデフォルトの優先度が割り当てられます。

3. 実際のワークロードがスケジュールされると、空のプレースホルダーコンテナが退避され、アプリケーションPodが即座にプロビジョニングされるようになります。

4. クラスターに**Pending**（Pause Container）Podがあるため、Cluster Autoscalerは、EKSノードグループに関連付けられた**ASG設定（`--max-size`）**に基づいて、追加のKubernetesワーカーノードをプロビジョニングします。

オーバープロビジョニングのレベルは、以下を調整することでコントロールできます：

1. pauseポッドの数（**replicas**）と**CPUおよびメモリ**リソース要求
2. EKSノードグループの最大ノード数（`maxsize`）

この戦略を実装することで、クラスターが常に新しいワークロードに対応できる余分な容量を持つことを確保でき、新しいPodがスケジュール可能になるまでの時間を短縮することができます。
