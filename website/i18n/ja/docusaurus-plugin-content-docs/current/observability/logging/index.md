---
title: "EKSでのロギング"
sidebar_position: 30
tmdTranslationSourceHash: 9a892a9e18bd9045ee4b850c00e4abb7
---

Kubernetesのロギングは、コントロールプレーンのロギング、ノードロギング、アプリケーションロギングに分けることができます。[Kubernetesコントロールプレーン](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components)は、Kubernetesクラスターを管理し、監査と診断目的のためのログを生成するコンポーネントの集合です。Amazon EKSでは、異なるコントロールプレーンコンポーネントのログを有効にし、Amazon CloudWatchに送信することができます。

コンテナはKubernetesクラスター内でPodとしてグループ化され、Kubernetesノード上で実行されるようにスケジュールされます。ほとんどのコンテナ化されたアプリケーションは標準出力と標準エラー出力に書き込み、コンテナエンジンは出力をロギングドライバーにリダイレクトします。Kubernetesでは、コンテナログはノード上の`/var/log/pods`ディレクトリにあります。CloudWatchとContainer Insightsを設定して、Amazon EKSの各ポッドのこれらのログをキャプチャすることができます。

このラボでは、以下のことを見ていきます：

- EKSコントロールプレーンログを有効にし、Amazon CloudWatchで確認する方法
- ロギングエージェント（Fluent Bit）を設定してPodログをAmazon CloudWatchにストリーミングする方法
