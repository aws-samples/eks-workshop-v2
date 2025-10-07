---
title: ノードの追加
sidebar_position: 10
kiteTranslationSourceHash: 6128417944a3f4ead27341932c0ec793
---

クラスターを使用している際、ワークロードのニーズをサポートするために追加のノードを追加するためにマネージドノードグループの設定を更新する必要があるかもしれません。ノードグループをスケールするには多くの方法がありますが、今回は `aws eks update-nodegroup-config` コマンドを使用します。

まず、`eksctl` コマンドを使用して、現在のノードグループのスケーリング設定を取得し、ノードの**最小サイズ**、**最大サイズ**、**希望するキャパシティ**を確認しましょう：

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

以下のコマンドを使用して、`eks-workshop` のノードグループを**希望するキャパシティ**のノード数を `3` から `4` に変更してスケールします：

```bash
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=4,maxSize=6,desiredSize=4
```

ノードグループに変更を加えた後、ノードのプロビジョニングと設定変更が有効になるまでに最大で**2〜3分**かかる場合があります。`eksctl` コマンドを使用して、ノードグループの設定を再度取得し、ノードの**最小サイズ**、**最大サイズ**、**希望するキャパシティ**を確認しましょう：

```bash hook=wait-node
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

4つのノードが表示されるまで、`--watch` 引数を使用して以下のコマンドでクラスター内のノードを監視します：

:::tip
ノードが以下の出力に表示されるまでに1分程度かかることがあります。リストがまだ3つのノードを表示している場合は、少し待ちましょう。
:::

```bash test=false
$ kubectl get nodes --watch
NAME                                          STATUS     ROLES    AGE  VERSION
ip-10-42-104-151.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-144-11.us-west-2.compute.internal    Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-146-166.us-west-2.compute.internal   NotReady   <none>   18s  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-182-134.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
```

4つのノードが表示されたら、`Ctrl+C` を使用してウォッチを終了できます。

新しいノードがまだクラスターに参加している途中であるため、ノードが `NotReady` ステータスを表示していることがあります。
