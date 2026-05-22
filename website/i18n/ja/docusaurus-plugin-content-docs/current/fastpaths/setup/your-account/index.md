---
title: あなたのAWSアカウントで
sidebar_position: 30
tmdTranslationSourceHash: '816ae7a5604c47cc743c1eddcfcdadec'
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

:::danger 警告
このワークショップ環境をあなたのAWSアカウントにプロビジョニングすると、リソースが作成され、**それらに関連するコストが発生します**。クリーンアップセクションでは、それらを削除してさらなる課金を防ぐ方法を説明します。
:::

このセクションでは、あなた自身のAWSアカウントでラボを実行するための環境をセットアップする方法について説明します。

最初のステップは、提供されているCloudFormationテンプレートを使用してIDEを作成することです。以下のAWS CloudFormationクイック作成リンクを使用して、適切なAWSリージョンで目的のテンプレートを起動してください。

| リージョン           | リンク                                                                                                                                                                                                                                                                                                                              |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [起動](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `eu-west-1`      | [起動](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `ap-southeast-1` | [起動](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF) |

これらの手順は上記のAWSリージョンでテストされており、他のリージョンでは変更なしに動作することは保証されていません。

:::warning

ワークショップ資料の性質上、IDE EC2インスタンスはあなたのアカウントで広範なIAM権限を必要とします。例えば、IAM roleの作成などです。続行する前に、CloudFormationテンプレートでIDEインスタンスに提供されるIAM権限を確認してください。

私たちはIAM権限の最適化に継続的に取り組んでいます。改善のご提案がある場合は、[GitHub issue](https://github.com/aws-samples/eks-workshop-v2/issues)を作成してください。

:::

画面の下部までスクロールして、IAM通知を承認してください：

<img src="/docs/introduction/setup/your-account/acknowledge-iam.webp" alt="acknowledge IAM" width="600" />

次に、**Create stack**ボタンをクリックします：

<img src="/docs/introduction/setup/your-account/create-stack.webp" alt="Create Stack" width="600" />

CloudFormationスタックのデプロイには約5分かかります。完了したら、**Outputs**タブから続行に必要な情報を取得できます：

<img src="/docs/introduction/setup/your-account/vscode-outputs.webp" alt="cloudformation outputs" width="600" />

`IdeUrl`出力には、IDEにアクセスするためにブラウザに入力するURLが含まれています。`IdePasswordSecret`には、IDE用に生成されたパスワードを含むAWS Secrets Managerシークレットへのリンクが含まれています。

パスワードを取得するには、`IdePasswordSecret`URLを開き、**Retrieve**ボタンをクリックします：

<img src="/docs/introduction/setup/your-account/vscode-password-retrieve.webp" alt="secretsmanager retrieve" width="600" />

その後、パスワードをコピーできるようになります：

<img src="/docs/introduction/setup/your-account/vscode-password-visible.webp" alt="password in Secrets Manager" width="600" />

提供されたIDE URLを開くと、パスワードの入力を求められます：

<img src="/docs/introduction/setup/your-account/vscode-password.webp" alt="IDE password prompt" width="600" />

パスワードを送信すると、最初のIDE画面が表示されます：

<img src="/docs/introduction/setup/your-account/vscode-splash.webp" alt="IDE initial screen" width="600" />

次のステップは、ラボ演習を実行するためのEKSクラスターを作成することです。以下のガイドのいずれかに従って、これらのラボの要件を満たすクラスターをプロビジョニングしてください：

- **(推奨)** [eksctl](./using-eksctl.md)
- (近日公開予定！) [Terraform](./using-terraform.md)、興味がありますか？ [GitHubリポジトリ](https://github.com/aws-samples/eks-workshop-v2/issues)でお知らせください
- (近日公開予定！) CDK

