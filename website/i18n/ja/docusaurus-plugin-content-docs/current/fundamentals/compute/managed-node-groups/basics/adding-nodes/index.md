---
title: ノードの追加
sidebar_position: 10
kiteTranslationSourceHash: 6128417944a3f4ead27341932c0ec793
---

クラスターでの作業中に、ワークロードのニーズをサポートするために追加のノードを追加するためにマネージドノードグループの設定を更新する必要がある場合があります。ノードグループをスケーリングするには多くの方法がありますが、ここでは `aws eks update-nodegroup-config` コマンドを使用します。

まず、現在のノードグループのスケーリング設定を取得し、`eksctl` コマンドを使用して**最小サイズ**、**最大サイズ**、**希望するキャパシティ**を確認しましょう：

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

`eks-workshop` のノードグループの**希望するキャパシティ**を `3` から `4` に変更して、以下のコマンドでスケーリングします：

```bash
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=4,maxSize=6,desiredSize=4
```

ノードグループに変更を加えた後、ノードのプロビジョニングと設定変更が有効になるまでに**2〜3分**かかる場合があります。もう一度 `eksctl` コマンドを使用してノードグループの設定を取得し、**最小サイズ**、**最大サイズ**、**希望するキャパシティ**を確認しましょう：

```bash hook=wait-node
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

以下のコマンドで `--watch` 引数を使用して、4つのノードが表示されるまでクラスター内のノードを監視します：

:::tip
ノードが下の出力に表示されるまでに1分程度かかる場合があります。まだ3つのノードしか表示されていない場合は、しばらくお待ちください。
:::

```bash test=false
$ kubectl get nodes --watch
NAME                                          STATUS     ROLES    AGE  VERSION
ip-10-42-104-151.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-144-11.us-west-2.compute.internal    Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-146-166.us-west-2.compute.internal   NotReady   <none>   18s  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-182-134.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
```

4つのノードが表示されたら、`Ctrl+C` を使用して監視を終了できます。

ノードが `NotReady` ステータスを示している場合があります。これは、新しいノードがまだクラスターに参加する過程にあるときに発生します。

