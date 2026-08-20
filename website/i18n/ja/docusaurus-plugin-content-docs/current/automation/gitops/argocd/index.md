---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでのArgo CDを使用した宣言的なGitOps継続的デリバリー。"
tmdTranslationSourceHash: 20cab646d274e73049994de42d932aec
---

::required-time

<details>
<summary>独自のアカウントで実施する場合は、<strong>前提条件 - IAM Identity Center</strong>についてお読みください</summary>

Amazon EKS Capability for Argo CDは、AWS IAM Identity Centerを通じてユーザーを認証するため、このラボでは、クラスターと同じアカウント・リージョンにIdentity Centerインスタンスと、サインインするためのユーザーが必要です。AWSが運営するイベントでは、これらはすでに設定されています。独自のアカウントで実施する場合は、開始前にインスタンスとArgo CD管理者ユーザーを配置する必要があります。

このラボはIdentity Centerから読み取るのみで、サービスの有効化やユーザーの作成は行いません。これは、重要なアイデンティティを保持している可能性のあるアカウント全体のディレクトリに書き込むためです。以下の手順で一度だけ設定してください。

**これらのコマンドは、ワークショップIDE外で管理者認証情報を使用して実行してください。** IDEのIAMロールは意図的に`sso:CreateInstance`と`identitystore:CreateUser`を除外しているため、IDEターミナルでは`AccessDeniedException`で失敗します。アカウントへの管理者アクセス権を持つシェルまたはコンソールセッションを使用してから、ラボの残りの部分についてはIDEに戻ってください。お好みであれば、[IAM Identity Centerコンソール](https://console.aws.amazon.com/singlesignon)からこれらすべてを実行することもできます。

**1. IAM Identity Centerを有効化**し、`ACTIVE`になるまで待ちます（通常1分未満）：

```bash test=false
$ aws sso-admin create-instance --name eks-workshop
$ aws sso-admin list-instances --query 'Instances[0].Status'
"ACTIVE"
```

**このアカウントとリージョンにすでにIdentity Centerインスタンスがありますか？** この手順をスキップして、ユーザーの作成に直接進んでください。ラボは既存のインスタンスを再利用し、MFAポリシーを含む設定を変更しません。

**2. ラボが期待するArgo CD管理者を作成**します：

```bash test=false
$ export IDENTITY_STORE_ID=$(aws sso-admin list-instances --no-paginate \
  --query 'Instances[0].IdentityStoreId' --output text)
$ aws identitystore create-user \
  --identity-store-id $IDENTITY_STORE_ID \
  --user-name eks-workshop \
  --display-name 'ArgoCD Workshop Admin' \
  --name 'GivenName=ArgoCD,FamilyName=Admin' \
  --emails 'Value=eks-workshop@example.com,Primary=true'
```

**3. ユーザーにパスワードを付与します。** Identity Centerはパスワードなしでユーザーを作成し、パスワードを設定するAPIがないため、これは初回サインインを通じて行われ、[Argo CDへのアクセス](./access_argocd.md)でカバーされています。AWSが運営するイベントでは、イベントプロビジョニングがこれを実行します。

**Organization インスタンスはサポートされていません。** アカウントがAWS Organizationに属し、その管理アカウントでIAM Identity Centerが有効化されている場合、このラボは実行を拒否します。アカウントが所有していないディレクトリにArgo CDアプリケーションやワークショップユーザーを登録しません。代わりに独自のIdentity Centerインスタンスを持つスタンドアロンアカウントを使用してください。

</details>

:::tip 始める前に
このセクションの環境を準備します：

```bash timeout=900 wait=120
$ prepare-environment automation/gitops/argocd
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS CodeCommitリポジトリを作成
- Amazon EKS Capability for Argo CDをデプロイし、そのためのIAMロールを作成し、上記で設定したIAM Identity CenterユーザーにArgo CDへのADMINアクセスを付与

AWSが運営するイベントでは、ここではCodeCommitリポジトリのみが作成されます。Capabilityの有効化には数分かかるため、イベントプロビジョニングがすでにそれを実行しており、IAMロールとADMIN付与も含まれています。

これらの変更を適用するTerraformは[ここ](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform)で確認できます。

:::

[Argo CD](https://argoproj.github.io/cd/)は、GitOpsの原則を実装するKubernetes向けの宣言的な継続的デリバリーツールです。Amazon EKS Capability for Argo CDを使用すると、Argo CDはAWSコントロールプレーンで実行されます（ワーカーノード上ではありません）。これにより、Argo CDコンポーネントのインストール、スケーリング、メンテナンスの運用オーバーヘッドなしに、完全なGitOpsワークフローを利用できます。

CNCFの卒業プロジェクトとして、Argo CDはいくつかの主要な機能を提供します：

- デプロイメント管理のための直感的なWeb UI
- マルチクラスター設定のサポート
- CI/CDパイプラインとの統合
- 堅牢なアクセス制御
- ドリフト検出機能
- 様々なデプロイメント戦略のサポート
- AWSによる可用性、スケーリング、アップグレードの管理
- SSO認証のためのネイティブIAM Identity Center統合

Argo CDを使用することで、Kubernetesアプリケーションがソース設定と一貫性を保ち、望ましい状態と実際の状態の間に発生する可能性のあるドリフトを自動的に修正することができます。

