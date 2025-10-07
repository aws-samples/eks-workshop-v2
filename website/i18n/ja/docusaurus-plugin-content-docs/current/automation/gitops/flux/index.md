---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceでのフラックスを使用した継続的かつ段階的なデリバリーを実装します。"
kiteTranslationSourceHash: 1d05d9460507fed9d11255be1c07ee97
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon EKSクラスタにAWS Load Balancerコントローラをインストールする
- EBS CSIドライバ用のEKSマネージドアドオンをインストールする

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/flux/.workshop/terraform)で確認できます。

:::

Fluxは、Gitリポジトリなどのソースコントロールのもとにある設定とKubernetesクラスタを同期させ、デプロイする新しいコードがある場合に、その設定の更新を自動化します。KubernetesのAPI拡張サーバーを使用して構築されており、PrometheusやKubernetesエコシステムの他のコアコンポーネントと統合できます。Fluxはマルチテナンシーをサポートし、任意の数のGitリポジトリを同期させます。

