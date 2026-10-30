---
title: "開発者必須"
sidebar_position: 50
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: "572b4034ea5aef74687a2baf8b252b67"
---

# 開発者必須

::required-time

:::tip 始める前に
このファストパスは、専用の Amazon EKS Auto Mode クラスターを使用します。Amazon EKS Auto Mode は、クラスター自体を超えて Kubernetes クラスターの AWS 管理を拡張し、コンピューティングオートスケーリング、ネットワーキング、ロードバランシング、DNS、ブロックストレージなど、ワークロードのスムーズな運用を可能にするインフラストラクチャを管理します。

このラボ用の環境を準備します:

```bash timeout=600
$ prepare-environment fastpaths/developer
```
:::

EKS ワークショップ開発者必須へようこそ！これは、ワークロードをデプロイする際に最も一般的に必要とされる Amazon EKS の機能を学ぶために、開発者向けに最適化されたラボのコレクションです。

この学習パスでは、以下を学びます:

- EKS でのコンテナ化されたアプリケーションのデプロイと管理
- Amazon EBS を使用した永続ストレージの操作
- ワークロードのオートスケーリングの実装
- ロードバランサーと Ingress によるアプリケーションの公開
- EKS Pod Identity を使用した DynamoDB などの AWS サービスの利用

それでは始めましょう！

