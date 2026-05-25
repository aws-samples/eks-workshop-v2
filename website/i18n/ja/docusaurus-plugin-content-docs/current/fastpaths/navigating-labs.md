---
title: ラボのナビゲーション
sidebar_position: 30
tmdTranslationSourceHash: 'c7e58b83cd9dad8d1b1ebf524ecb56c6'
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

このウェブサイトと提供されるコンテンツの操作方法を確認しましょう。

## 構造

このワークショップのコンテンツは以下で構成されています:

1. 個別のラボ演習
2. ラボに関連する概念を説明するサポートコンテンツ

ラボ演習は、どのモジュールも独立した演習として実行できるように設計されています。ラボ演習は左側のサイドバーに表示され、`LAB`アイコンで示されます。

## IDE を開く

**AWS イベントに参加している場合**は、Workshop Studio のスタートページの下部にある *Event Outputs* セクションから IDE を開きます。

<img src={require('@site/static/img/fastpaths/ide-open.png').default} alt="Event Outputs copy/paste" width="500" />

**自分のアカウントで実行している場合**は、CloudFormation スタックの Outputs タブで `IdeUrl` を見つけてください。詳細は[セットアップガイド](/docs/fastpaths/setup/your-account)を参照してください。

## ラボの開始

:::caution
各ラボには「始める前に」セクションがあり、最初に実行する必要がある `prepare-environment` コマンドが含まれています。必ずそのページから開始してください。ラボの途中から始めると、予期しない動作が発生します。
:::

## ヒント

### コピー/ペースト権限
ブラウザによっては、VS Code Terminal へのコンテンツのコピー/ペーストの方法が異なる場合があります。

<Tabs>
  <TabItem value="Google Chrome" label="Google Chrome (推奨)" default>
    ターミナルでコンテンツを最初にペーストしようとすると、次のようなブラウザのポップアップが表示されます:

    <img src={require('@site/static/docs/introduction/vscode-copy-paste.webp').default} alt="Chrome copy/paste" width="480" />

    **Allow** ボタンをクリックして、この機能を有効にします。これ以降、コピー/ペーストは簡単になります。このワークショップでは、可能であれば Google Chrome の使用をお勧めします。
  </TabItem>
  <TabItem value="Firefox/Safari" label="Firefox/Safari">
    ターミナルでコンテンツをペーストしようとするたびに、マウスポインタの隣に次のスクリーンショットに示すような小さなボタンが表示されます。コピーしたコンテンツを実際にペーストするには、それをクリックする必要があります。

    <img src={require('@site/static/img/fastpaths/introduction/paste-in-firefox-safari.png').default} alt="Firefox/Safari copy/paste" width="480" />

    さらに、エディタウィンドウの右下隅に次のポップアップボックスが表示される場合がありますが、これは閉じて無視してかまいません。

    <img src={require('@site/static/img/fastpaths/introduction/paste-warning-in-firefox-safari.png').default} alt="Firefox/Safari copy/paste" width="480" />
  </TabItem>
</Tabs>

### ターミナルコマンド

このワークショップでのほとんどの操作は、手動で入力するか IDE ターミナルにコピー/ペーストするターミナルコマンドで行います。ターミナルコマンドは次のように表示されます:

```bash test=false
$ echo "This is an example command"
```

`echo "This is an example command"` の上にマウスを置き、クリックしてそのコマンドをクリップボードにコピーします。

次のように、サンプル出力を含むコマンドも表示されます:

```bash test=false
$ date
Fri Aug 30 12:25:58 MDT 2024
```

「クリックしてコピー」機能を使用すると、コマンドのみがコピーされ、サンプル出力は無視されます。

コンテンツで使用されるもう1つのパターンは、1つのターミナルに複数のコマンドを表示することです:

```bash test=false
$ echo "This is an example command"
This is an example command
$ date
Fri Aug 30 12:26:58 MDT 2024
```

この場合、各コマンドを個別にコピーするか、ターミナルウィンドウの右上隅にあるクリップボードアイコンを使用してすべてのコマンドをコピーできます。試してみてください!

### Kustomize の使用

[Kustomize](https://kustomize.io/) を使用すると、宣言的な「kustomization」ファイルを使用して Kubernetes マニフェストファイルを管理できます。これにより、Kubernetes リソースの「ベース」マニフェストを表現し、構成、カスタマイズ、多くのリソース全体で横断的な変更を簡単に行う機能が提供されます。

このワークショップでは、Kustomize に関連する次の2種類のコマンドが表示されます。

1. `kubectl kustomize some-deployment.yaml` - このコマンドは、Kustomize 設定を使用して yaml のカスタマイズされたバージョンを**生成**します。リソースはデプロイされません。

1. `kubectl apply -k some-deployment.yaml` - このコマンドは、Kustomize 設定を使用して yaml のカスタマイズされたバージョンを直接**適用**し、リソースをデプロイします。

Kustomize の詳細については、https://kustomize.io/ を参照してください。

## 次のステップ

このワークショップの形式に慣れたら、[Getting Started](/docs/fastpaths/getting-started) に進んでください。
