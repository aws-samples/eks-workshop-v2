---
title: "さらなるスケーリング"
sidebar_position: 50
tmdTranslationSourceHash: 860ea9f5106b50857abe6239ba4ce69e
---

このラボ演習では、以前のCluster Autoscalerセクションよりもさらに大きく、アプリケーションアーキテクチャ全体をスケールアップし、応答性の違いを観察します。

以下の設定ファイルを適用して、アプリケーションコンポーネントをスケールアップします：

```file
manifests/modules/autoscaling/compute/overprovisioning/scale/deployment.yaml
```

これらの更新をクラスターに適用しましょう：

```bash timeout=180 hook=overprovisioning-scale
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/scale
$ kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
```

新しいポッドがロールアウトされると、ワークロードサービスが利用できるリソースをpauseポッドが消費しているため、最終的に競合が発生します。優先順位の設定により、ワークロードポッドが開始できるようにpauseポッドが退避されます。これにより、一部または全てのpauseポッドが`Pending`状態になります：

```bash
$ kubectl get pod -n other -l run=pause-pods
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   0/1     Pending   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
```

この退避プロセスにより、ワークロードポッドはより迅速に`ContainerCreating`および`Running`状態に移行でき、クラスターオーバープロビジョニングのメリットを示しています。

しかし、これらのポッドが保留状態になっているのはなぜでしょうか？Cluster Autoscalerが追加のノードをプロビジョニングすべきではないでしょうか？答えは、クラスター用に設定されているManaged Node Groupの最大サイズが`6`であるため、ラボクラスターのインスタンス数の上限に達したということです。
