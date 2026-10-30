---
title: eksctl を使用する
sidebar_position: 20
pagination_next: fastpaths/navigating-labs
tmdTranslationSourceHash: '35b6089a346b6ed8dbdd09ac89809ae2'
---

このセクションでは、[eksctl ツール](https://eksctl.io/)を使用してラボ演習用のクラスターを構築する方法を説明します。これは最も簡単に始められる方法であり、ほとんどの学習者に推奨されます。

`eksctl` ユーティリティは、IDE 環境にプリインストールされているため、すぐにクラスターを作成できます。以下は、クラスターの構築に使用される設定です：

::yaml{file="manifests/../cluster/eksctl/cluster-auto.yaml" paths="availabilityZones,metadata.name,autoModeConfig.nodePools" title="cluster.yaml"}

1. 3つのアベイラビリティーゾーンにまたがる VPC を作成
2. デフォルトで `eks-workshop-auto` という名前の EKS クラスターを作成
3. EKS Auto Mode の組み込み NodePool を有効化


以下のように設定ファイルを適用します：

```bash
$ export EKS_CLUSTER_AUTO_NAME=eks-workshop-auto
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster-auto.yaml | \
envsubst | eksctl create cluster -f -
```

このプロセスは完了まで約 20 分かかります。

## 次のステップ

クラスターの準備ができたら、「ラボのナビゲーション」セクションに進んで開始してください。

import Link from '@docusaurus/Link';

<Link className="button button--primary button--lg" to="/docs/fastpaths/navigating-labs">ラボのナビゲーションに進む →</Link>

<br/><br/>

---

## クリーンアップ（ワークショップ全体の終了後）

:::tip
以下は、EKS クラスターの使用が終了した後にリソースをクリーンアップする方法を示しています。これらの手順を完了すると、AWS アカウントへのさらなる課金を防ぐことができます。
:::

IDE 環境を削除する前に、前の手順で設定したクラスターをクリーンアップします。

まず、`delete-environment` を使用して、サンプルアプリケーションと残っているラボインフラストラクチャが削除されることを確認します：

```bash
$ delete-environment
```

次に、`eksctl` でクラスターを削除します：

```bash
$ eksctl delete cluster $EKS_CLUSTER_AUTO_NAME --wait
```

これで、IDE の[クリーンアップ](./cleanup.md)に進むことができます。

