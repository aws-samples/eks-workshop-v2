---
title: マネージドノードグループの基礎
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceのマネージドノードグループの基本を学びます。"
kiteTranslationSourceHash: 6869504270d3dcdc1e2f17cb75ab7d73
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=30
$ prepare-environment fundamentals/mng/basics
```

:::

入門ラボでは、サンプルアプリケーションをEKSにデプロイし、実行中のPodを確認しました。しかし、これらのPodはどこで実行されているのでしょうか？

あなたのために事前にプロビジョニングされたデフォルトのマネージドノードグループを調査できます：

```bash
$ eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_DEFAULT_MNG_NAME
```

マネージドノードグループには、この出力から確認できるいくつかの属性があります：

- このグループ内のノード数の最小、最大、および希望するカウントの設定。この文脈では、最小値と最大値は単に基盤となるAutoscaling Groupの設定された境界であり、コンピューティングのオートスケーリングの有効化については[それぞれのラボ](/docs/autoscaling/compute)で探求します。
- このノードグループのインスタンスタイプは`m5.large`です
- `AL2023_x86_64_STANDARD`は、Amazon EKS最適化Amazon Linux 2023 AMIを使用していることを示しています。詳細については[ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)を参照してください。

また、ノードとアベイラビリティーゾーンでの配置を検査することもできます。

```bash
$ kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

以下のことが確認できるはずです：

- ノードは様々なアベイラビリティーゾーンの複数のサブネットに分散されており、高可用性を提供しています

このモジュールの過程で、MNGの基本的な機能を実証するためにこのノードグループに変更を加えていきます。

