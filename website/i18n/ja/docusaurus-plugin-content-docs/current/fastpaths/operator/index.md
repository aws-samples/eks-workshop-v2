---
title: "Operator Essentials"
sidebar_position: 60
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: '9b2d0b60ba5cabc544ba2dab1c87470d'
---

# Operator Essentials

::required-time

:::tip 始める前に
このファストパスでは、専用の Amazon EKS Auto Mode クラスターを使用します。Amazon EKS Auto Mode は、クラスター自体を超えて Kubernetes クラスターの AWS 管理を拡張し、コンピュートのオートスケーリング、ネットワーキング、ロードバランシング、DNS、ブロックストレージなど、ワークロードのスムーズな運用を可能にするインフラストラクチャを管理します。

このラボ用の環境を準備します：

```bash timeout=600
$ prepare-environment fastpaths/operator
```
:::

EKS Workshop Operator Essentials へようこそ！これは、EKS クラスターを運用する際に最も一般的に必要とされる Amazon EKS の機能をオペレーターが学習するために最適化された一連のラボです。

この一連の演習を通じて、以下を学習します：

- Karpenter によるクラスターオートスケーリングの設定
- Pod 間トラフィックを保護するためのネットワークポリシーの実装
- EKS におけるシークレットの操作
- EKS Pod Identity を使用した DynamoDB などの AWS サービスの利用

さあ、始めましょう！
