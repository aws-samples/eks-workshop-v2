---
title: "kro - Kube リソースオーケストレーター"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service 上で kro を使用して複雑な Kubernetes リソースグラフを構成および管理します。"
tmdTranslationSourceHash: 323089b6c7dc70bb60357518ab54bc97
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment automation/controlplanes/kro
```

これにより、ラボ環境に以下の変更が加えられます：

- EKS、IAM、DynamoDB 用の AWS Controllers for Kubernetes コントローラーをインストール
- AWS Load Balancer Controller をインストール
- UI ワークロード用の Ingress リソースを作成

これらの変更を適用する Terraform は[ここ](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/kro/.workshop/terraform)で確認できます。

:::

[kro (Kube Resource Orchestrator)](https://kro.run/) は、関連する Kubernetes リソースのグループを作成するためのカスタム API を定義できるオープンソースの Kubernetes オペレーターです。kro を使用すると、CEL (Common Expression Language) 式を使用してリソース間の関係を定義し、自動的に作成順序を決定する ResourceGraphDefinitions (RGDs) を作成できます。

kro を使用すると、インテリジェントな依存関係処理を備えた高レベルの抽象化に複数の Kubernetes リソースを構成できます - リソースがどのように相互に参照しているかを分析することで、リソースをデプロイする正しい順序を自動的に決定します。CEL 式を使用してリソース間で値を渡したり、条件付きロジックを含めたり、ユーザーエクスペリエンスを簡素化するためのデフォルト値を定義したりすることができます。

このラボでは、まず WebApplication ResourceGraphDefinition を使用してインメモリデータベースを持つ完全な **Carts** コンポーネントをデプロイすることで、kro の機能を探ります。次に、ベースの WebApplication テンプレートを拡張して Amazon DynamoDB ストレージを追加する WebApplicationDynamoDB ResourceGraphDefinition を構成することでこれを強化します。

