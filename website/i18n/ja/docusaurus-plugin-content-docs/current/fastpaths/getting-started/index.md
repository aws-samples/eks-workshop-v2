---
title: はじめに
sidebar_position: 40
description: "EKS にサンプル小売アプリケーションをデプロイします。"
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: 'c4b4ab1218ac34dbc4752330a705553a'
---

:::tip 始める前に
この Fast Path では、専用の Amazon EKS Auto Mode クラスターを使用します。Amazon EKS Auto Mode は、クラスター自体を超えて Kubernetes クラスターの AWS 管理を拡張し、コンピュートのオートスケーリング、ネットワーキング、ロードバランシング、DNS、ブロックストレージなど、ワークロードのスムーズな運用を可能にするインフラストラクチャを管理します。

このラボ用に環境を準備します:

```bash
$ prepare-environment fastpaths/getting-started
```
:::

EKS ワークショップの最初のハンズオンラボへようこそ。この演習の目標は、今後の多くのラボ演習で使用するサンプルアプリケーションに慣れ、そうすることで EKS へのワークロードのデプロイに関連するいくつかの基本的な概念に触れることです。アプリケーションのアーキテクチャを探索し、EKS クラスターにコンポーネントをデプロイします。

ラボ環境の EKS クラスターに最初のワークロードをデプロイして、探索してみましょう！

