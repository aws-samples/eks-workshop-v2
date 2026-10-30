---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでFluxを使用した継続的かつプログレッシブなデリバリーを実装します。"
tmdTranslationSourceHash: 323b14b06c3889c7d661e328aee82bcd
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS CodeCommitリポジトリを作成する
- Amazon EKSクラスタにAWS Load Balancerコントローラをインストールする
- EBS CSIドライバ用のEKSマネージドアドオンをインストールする

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/flux/.workshop/terraform)で確認できます。

:::

Fluxは、GitOpsの方法論をKubernetesに適用し、Gitリポジトリなどのソースコントロール下に保管された設定を信頼できる唯一の情報源として使用します。Fluxは、クラスタをGitに保存された設定と同期させ、プッシュされた変更を自動的に調整します。KubernetesのAPI拡張サーバーを使用して構築されており、PrometheusやKubernetesエコシステムの他のコアコンポーネントと統合できます。Fluxはマルチテナンシーをサポートし、任意の数のGitリポジトリを同期できます。

