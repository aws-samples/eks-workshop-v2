---
title: eksctlを使用する
sidebar_position: 20
kiteTranslationSourceHash: 64bca6c359b7e98745bbfb3b91d91197
---

このセクションでは、[eksctlツール](https://eksctl.io/)を使用してラボ演習用のクラスターを構築する方法を説明します。これは開始するための最も簡単な方法であり、ほとんどの学習者におすすめです。

`eksctl`ユーティリティはIDE環境に事前にインストールされているため、すぐにクラスターを作成できます。これはクラスターを構築するために使用される構成です：

::yaml{file="manifests/../cluster/eksctl/cluster.yaml" paths="availabilityZones,metadata.name,iam,managedNodeGroups,addons.0.configurationValues" title="cluster.yaml"}

1. 3つのアベイラビリティーゾーンにまたがるVPCを作成する
2. EKSクラスターを作成する（デフォルト名は`eks-workshop`）
3. IAM OIDCプロバイダーを作成する
4. `default`という名前のマネージドノードグループを追加する
5. プレフィックス委任を使用するようにVPC CNIを構成する

次のように構成ファイルを適用します：

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

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
