---
title: はじめに
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceでワークロードを実行する基本を学びましょう。"
tmdTranslationSourceHash: 7cdfb6c9bfdda46e240ba735baaedb14
---

::required-time

EKSワークショップの最初のハンズオンラボへようこそ。この演習の目的は、今後の多くのラボ演習で使用するサンプルアプリケーションに慣れ親しみ、その過程でEKSにワークロードをデプロイすることに関する基本的な概念に触れることです。アプリケーションのアーキテクチャを探索し、コンポーネントをEKSクラスターにデプロイします。

それでは、ラボ環境のEKSクラスターに最初のワークロードをデプロイして探索してみましょう！

始める前に、IDE環境とEKSクラスターを準備するために次のコマンドを実行する必要があります：

```bash
$ prepare-environment introduction/getting-started
```

このコマンドは何をしているのでしょうか？このラボでは、必要なKubernetesマニフェストファイルがファイルシステム上に存在するように、EKS WorkshopのGitリポジトリをIDE環境にクローンしています。

以降のラボでも同様にこのコマンドを実行しますが、その際には次の2つの重要な追加機能を実行します：

1. EKSクラスターを初期状態にリセットする
2. 次のラボ演習に必要な追加コンポーネントをクラスターにインストールする
