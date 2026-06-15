---
title: ラボのナビゲーション
sidebar_position: 30
tmdTranslationSourceHash: 'ce60b02ae62eb9aa4bbd5a450bd5f448'
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

このウェブサイトと提供されているコンテンツのナビゲーション方法を確認しましょう。

## 構造

このワークショップのコンテンツは以下で構成されています：

1. 個別のラボ演習
2. ラボに関連する概念を説明するサポートコンテンツ

ラボ演習は、任意のモジュールを独立した演習として実行できるように設計されています。ラボ演習は左側のサイドバーに表示され、`LAB` アイコンで指定されています。

## IDE を開く

まだ開いていない場合は、スタートページの下部にある *Event outputs* セクションから IDE を開くことができます。

 ![Event Outputs copy/paste](/img/fastpaths/ide-open.png)

## 環境の準備

`prepare-environment` ツールは、各セクションのラボ環境をセットアップおよび設定するのに役立ちます。次のように実行するだけです：

```
$ prepare-environment $MODULE_NAME
```

### 基本的な使用パターン
```
$ prepare-environment $MODULE_NAME/$LAB
```

**例**
```
# Getting started ラボの場合
$ prepare-environment introduction/getting-started

# Karpenter autoscaling の場合
$ prepare-environment autoscaling/compute/karpenter

# EBS を使用したストレージの場合
$ prepare-environment fundamentals/storage/ebs

# ネットワーキング security groups の場合
$ prepare-environment networking/securitygroups-for-pods
```

:::caution
各ラボは「BEFORE YOU START」バッジで示されたページから開始する必要があります。ラボの途中から開始すると、予測不可能な動作が発生します。
:::

## クラスターのリセット（Modular Section のみ）

誤ってクラスターやモジュールを機能しない方法で設定してしまった場合、EKS クラスターをできる限りリセットするメカニズムが提供されており、いつでも実行できます。`prepare-environment` コマンドを実行し、完了するまで待つだけです。これには、実行時のクラスターの状態に応じて数分かかる場合があります。

```bash
$ prepare-environment
```

## ヒント

### コピー＆ペーストの許可
ブラウザによっては、VSCode ターミナルにコンテンツを初めてコピー＆ペーストすると、次のようなプロンプトが表示される場合があります：

<img src="/docs/introduction/vscode-copy-paste.webp" alt="VSCode copy/paste" width="480" />

### ターミナルコマンド

このワークショップでのやり取りのほとんどは、ターミナルコマンドを使用して行われます。これらのコマンドは、手動で入力するか、IDE ターミナルにコピー＆ペーストできます。ターミナルコマンドは次のように表示されます：

```bash test=false
$ echo "This is an example command"
```

`echo "This is an example command"` の上にマウスをホバーしてクリックすると、そのコマンドがクリップボードにコピーされます。

また、次のようなサンプル出力を含むコマンドにも遭遇します：

```bash test=false
$ date
Fri Aug 30 12:25:58 MDT 2024
```

「クリックしてコピー」機能を使用すると、コマンドのみがコピーされ、サンプル出力は無視されます。

コンテンツで使用されるもう1つのパターンは、単一のターミナルに複数のコマンドを表示することです：

```bash test=false
$ echo "This is an example command"
This is an example command
$ date
Fri Aug 30 12:26:58 MDT 2024
```

この場合、各コマンドを個別にコピーするか、ターミナルウィンドウの右上にあるクリップボードアイコンを使用してすべてのコマンドをコピーできます。試してみてください！

## 次のステップ

このワークショップの形式に慣れたら、[Application Overview](/docs/introduction/getting-started/about) に進んでサンプルアプリケーションについて学習し、その後 [Getting Started](/docs/introduction/getting-started) ラボに進むか、上部のナビゲーションバーを使用してワークショップの任意のモジュールにスキップしてください。

