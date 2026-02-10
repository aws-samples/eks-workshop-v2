---
title: "ワーカーノード"
sidebar_position: 50
description: "Amazon EKS マネージドノードグループのワーカーノードを健全な状態に戻します。"
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: dfdf1b903626dbcdbab94a3d5d06ea47
---

以下のワーカーノードのシナリオでは、様々なAWS EKSワーカーノードの問題をトラブルシューティングする方法を学びます。異なるシナリオでは、ノードがクラスターに参加できない、または「Not Ready」状態のままになる原因を説明し、解決策を用いて修正します。始める前に、マネージドノードグループの一部としてワーカーノードがどのようにデプロイされるかについて詳しく知りたい場合は、[基礎モジュール](../../fundamentals/compute/managed-node-groups)をご覧ください。

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/workernodes
```

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/workernodes/.workshop/terraform)で確認できます。

:::
:::info

ラボの準備には数分かかる場合があり、ラボ環境に以下の変更を加えます：

- new_nodegroup_1、new_nodegroup_2、new_nodegroup_3という名前の新しいマネージドノードグループを作成し、希望するマネージドノードグループ数を1に設定します
- ノード参加の失敗やready状態の問題を引き起こす問題をマネージドノードグループに導入します
- Kubernetesリソース（deployment、daemonset、namespace、configmaps、priority-class）をデプロイします

:::

