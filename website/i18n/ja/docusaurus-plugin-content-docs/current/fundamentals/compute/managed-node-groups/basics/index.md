---
title: MNG の基本
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service のマネージドノードグループの基本を学びます。"
tmdTranslationSourceHash: 3917d0b8357b8a5a37722a603ced394a
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=30
$ prepare-environment fundamentals/mng/basics
```

:::

はじめにのラボでは、サンプルアプリケーションを EKS にデプロイし、実行中の Pod を確認しました。しかし、これらの Pod はどこで実行されているのでしょうか？

あなたのために事前にプロビジョニングされたデフォルトのマネージドノードグループを調べることができます：

```bash
$ eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_DEFAULT_MNG_NAME
```

このアウトプットから、マネージドノードグループの複数の属性を確認することができます：

- このグループ内のノード数の最小値、最大値、および希望数の設定。この文脈では、最小値と最大値は単に基盤となる Autoscaling Group の設定された境界であり、コンピュートオートスケーリングの有効化は[対応するラボ](/docs/autoscaling/compute)で詳しく説明します。
- このノードグループのインスタンスタイプは `m5.large` です
- `AL2023_x86_64_STANDARD` はAmazon EKS 最適化 Amazon Linux 2023 AMI を使用していることを示しています。詳細は[ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)を参照してください。

また、ノードとアベイラビリティーゾーンでの配置を調査することもできます。

```bash
$ kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

次のことが確認できるはずです：

- ノードは高可用性を提供するために、複数のサブネットと様々なアベイラビリティーゾーンに分散しています

このモジュールの過程で、MNG の基本的な機能を示すためにこのノードグループに変更を加えます。
