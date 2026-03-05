---
title: "オーバープロビジョニングの設定"
sidebar_position: 35
tmdTranslationSourceHash: c3d3a0fcb9b4afc81fd1b6078f840900
---

オーバープロビジョニングを効果的に実装するには、アプリケーション用に適切な `PriorityClass` リソースを作成することがベストプラクティスと考えられています。まず、`globalDefault: true` フィールドを使用してグローバルデフォルトのプライオリティクラスを作成しましょう。このデフォルトの `PriorityClass` は、`PriorityClassName` を指定していないポッドとデプロイメントに割り当てられます。

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml" paths="value,globalDefault"}

1. 値は必須の `value` フィールドで指定されます。値が高いほど、優先度が高くなります。
2. `globalDefault` フィールドは、この PriorityClass の値が priorityClassName のないポッドに使用されるべきであることを示します。

次に、オーバープロビジョニングに使用するポーズポッド専用の `PriorityClass` を作成し、優先度の値を `-1` に設定します。

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml" paths="value"}

1. 優先度の値「-1」により、空の「ポーズ」コンテナがプレースホルダーとして機能します。実際のワークロードがスケジュールされると、空のプレースホルダーコンテナは退避され、アプリケーションポッドが即座にプロビジョニングできるようになります。

ポーズポッドは、環境に必要なオーバープロビジョニングの量に基づいて、十分な数の利用可能なノードを確保する上で重要な役割を果たします。EKS ノードグループの ASG の `--max-size` パラメータを考慮することが重要です。Cluster Autoscaler は ASG で指定された最大数を超えてノードの数を増やすことはありません。

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/deployment-pause.yaml" paths="spec.replicas,spec.template.spec.priorityClassName"}

1. ポーズポッドのレプリカを2つデプロイ
2. 先ほど作成したプライオリティクラスを使用

これらのポッドはそれぞれ `6.5Gi` のメモリを要求しているため、`m5.large` インスタンスをほぼ1つ消費し、結果として常に2つの「予備」ワーカーノードが利用可能な状態になります。

これらの更新をクラスタに適用しましょう：

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
priorityclass.scheduling.k8s.io/default created
priorityclass.scheduling.k8s.io/pause-pods created
deployment.apps/pause-pods created
$ kubectl rollout status -n other deployment/pause-pods --timeout 300s
```

このプロセスが完了すると、ポーズポッドが実行中になります：

```bash
$ kubectl get pods -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-7f7669b6d7-v27sl   1/1     Running   0          5m6s
pause-pods-7f7669b6d7-v7hqv   1/1     Running   0          5m6s
```

これで、Cluster Autoscaler によって追加のノードがプロビジョニングされたことを確認できます：

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-111.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-133.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   vVAR::KUBERNETES_NODE_VERSION
```

これらの2つの追加ノードは、私たちのポーズポッド以外のワークロードは実行していません。これらのポッドは「実際の」ワークロードがスケジュールされると退避されます。
