---
title: eksctlを使用する
sidebar_position: 20
tmdTranslationSourceHash: ea1d2d559b822ccca49dd946a0bd30d6
---

このセクションでは、[eksctlツール](https://eksctl.io/)を使用してラボ演習用のクラスターを構築する方法を説明します。これは開始するための最も簡単な方法であり、ほとんどの学習者におすすめです。

`eksctl`ユーティリティはIDE環境に事前にインストールされているため、すぐにクラスターを作成できます。これはクラスターを構築するために使用される構成です：

::yaml{file="manifests/../cluster/eksctl/cluster.yaml" paths="availabilityZones,metadata.name,iam,managedNodeGroups,addons.0.configurationValues" title="cluster.yaml"}

1. 3つのアベイラビリティーゾーンにまたがるVPCを作成する
2. EKSクラスターを作成する（デフォルト名は`eks-workshop`）
3. IAM OIDCプロバイダーを作成する
4. `default`という名前のマネージドノードグループを追加する
5. Prefix Delegationを使用するようにVPC CNIを構成する

次のように構成ファイルを適用します：

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | with-iam-boundary | eksctl create cluster -f -
```

`with-iam-boundary`は、eksctlが作成するIAM roleにワークショップのIAM permissions boundaryを追加するIDE内のヘルパーです。IDEは、これを持つIAM roleのみを作成することが許可されています。

このプロセスは完了するまでに約20分かかります。

## 次のステップ

クラスターの準備ができたら、[ラボのナビゲーション](/docs/introduction/navigating-labs)セクションに進むか、上部のナビゲーションバーを使用してワークショップの任意のモジュールに進んでください。ワークショップを完了したら、以下の手順に従って環境をクリーンアップしてください。

## クリーンアップ（ワークショップを終了した後の手順）

:::tip
以下は、EKSクラスターの使用が終了した後にリソースをクリーンアップする方法を示しています。これらの手順を完了することで、AWSアカウントへの追加料金の発生を防ぐことができます。
:::

IDE環境を削除する前に、前の手順でセットアップしたクラスターをクリーンアップします。

まず、`delete-environment`を使用して、サンプルアプリケーションと残っているラボインフラストラクチャが削除されていることを確認します：

```bash
$ delete-environment
```

次に、`eksctl`でクラスターを削除します：

```bash
$ eksctl delete cluster $EKS_CLUSTER_NAME --wait
```

これで[クリーンアップ](./cleanup.md)に進んでIDEをクリーンアップすることができます。
