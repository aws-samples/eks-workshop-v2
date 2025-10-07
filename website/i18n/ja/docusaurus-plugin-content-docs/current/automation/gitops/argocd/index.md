---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでのArgo CDを使用した宣言的なGitOps継続的デリバリー。"
kiteTranslationSourceHash: a1187126cce56eb990c6be52d0698b2b
---

::required-time

:::tip 始める前に
このセクションの環境を準備します：

```bash timeout=300 wait=120
$ prepare-environment automation/gitops/argocd
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS CodeCommitリポジトリの作成
- リポジトリへの認証のためのIAMユーザーとSSHキーの作成

これらの変更を適用するTerraformは[ここ](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform)で確認できます。

:::

[Argo CD](https://argoproj.github.io/cd/)は、GitOpsの原則を実装するKubernetes向けの宣言的な継続的デリバリーツールです。クラスター内でコントローラーとして動作し、継続的にGitリポジトリの変更を監視し、Gitリポジトリで定義された望ましい状態に合わせてアプリケーションを自動的に同期します。

CNCFの卒業プロジェクトとして、Argo CDはいくつかの主要な機能を提供します：

- デプロイメント管理のための直感的なWeb UI
- マルチクラスター設定のサポート
- CI/CDパイプラインとの統合
- 堅牢なアクセス制御
- ドリフト検出機能
- 様々なデプロイメント戦略のサポート

Argo CDを使用することで、Kubernetesアプリケーションがソース設定と一貫性を保ち、望ましい状態と実際の状態の間に発生する可能性のあるドリフトを自動的に修正することができます。

