---
title: "ワーカーノード"
sidebar_position: 50
description: "Amazon EKS マネージドノードグループのワーカーノードを健全な状態に戻します。"
sidebar_custom_props: { "module": true }
kiteTranslationSourceHash: 8845035d2b7c26416739d3f9469f292d
---

以下のワーカーノードのシナリオでは、様々なAWS EKSワーカーノードの問題をトラブルシューティングする方法を学びます。異なるシナリオでは、ノードがクラスターに参加できない、または「準備完了でない」状態のままになる原因を特定し、解決策を見つけ出します。始める前に、マネージドノードグループの一部としてワーカーノードがどのようにデプロイされるかについての詳細は[基礎モジュール](/docs/fundamentals/managed-node-groups)をご覧ください。

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/workernodes
```

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/workernodes/.workshop/terraform)で確認できます。


:::
:::info

ラボの準備には数分かかる場合があり、あなたのラボ環境に以下の変更を行います：
- new_nodegroup_1、new_nodegroup_2、new_nodegroup_3という名前の新しいマネージドノードグループを作成し、希望するマネージドノードグループ数を1に設定します
- マネージドノードグループにノード参加の失敗や準備の問題を引き起こす問題を導入します
- Kubernetesリソース（デプロイメント、デーモンセット、名前空間、コンフィグマップ、プライオリティクラス）をデプロイします

:::

