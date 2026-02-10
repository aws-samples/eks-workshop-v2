---
title: あなたのAWSアカウントで
sidebar_position: 30
tmdTranslationSourceHash: 0771be9fbb8a2646bb579605cbec1de9
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

:::danger 警告
このワークショップ環境をあなたのAWSアカウントでプロビジョニングすると、リソースが作成され、**それに関連するコストが発生します**。クリーンアップセクションでは、これらを削除してさらなる料金が発生しないようにするためのガイドを提供しています。
:::

このセクションでは、あなた自身のAWSアカウントでラボを実行するための環境のセットアップ方法について説明します。

最初のステップは、提供されたCloudFormationテンプレートを使用してIDEを作成することです。以下のAWS CloudFormation クイック作成リンクを使用して、適切なAWSリージョンで目的のテンプレートを起動してください。

| リージョン       | リンク                                                                                                                                                                                                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [起動](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `eu-west-1`      | [起動](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `ap-southeast-1` | [起動](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF) |

これらの手順は上記のAWSリージョンでテストされており、修正なしに他のリージョンで動作する保証はありません。

:::warning

ワークショップの教材の性質上、IDE EC2インスタンスはIAMロールの作成など、アカウント内で広範なIAM権限を必要とします。続行する前に、CloudFormationテンプレートでIDEインスタンスに提供されるIAM権限を確認してください。

私たちはIAM権限の最適化に継続的に取り組んでいます。改善のための提案がありましたら、[GitHubイシュー](https://github.com/aws-samples/eks-workshop-v2/issues)を立ち上げてください。

:::

画面の下部にスクロールしてIAM通知を承認してください：

![IAMの承認](/docs/introduction/setup/your-account/acknowledge-iam.webp)

次に**スタックの作成**ボタンをクリックします：

![スタックの作成](/docs/introduction/setup/your-account/create-stack.webp)

CloudFormationスタックは約5分でデプロイされ、完了すると続行に必要な情報を**出力**タブから取得できます：

![cloudformation出力](/docs/introduction/setup/your-account/vscode-outputs.webp)

`IdeUrl`出力にはIDEにアクセスするためにブラウザに入力するURLが含まれています。`IdePasswordSecret`には、IDEの生成されたパスワードを含むAWS Secrets Managerシークレットへのリンクが含まれています。

パスワードを取得するには、`IdePasswordSecret`のURLを開き、**取得**ボタンをクリックします：

![secretsmanager取得](/docs/introduction/setup/your-account/vscode-password-retrieve.webp)

その後、パスワードがコピーできるようになります：

![Secrets Managerのパスワード](/docs/introduction/setup/your-account/vscode-password-visible.webp)

提供されたIDE URLを開くと、パスワードの入力を求められます：

![IDEパスワードプロンプト](/docs/introduction/setup/your-account/vscode-password.webp)

パスワードを送信すると、初期IDE画面が表示されます：

![IDE初期画面](/docs/introduction/setup/your-account/vscode-splash.webp)

次のステップは、ラボ演習を行うためのEKSクラスターを作成することです。これらのラボの要件を満たすクラスターをプロビジョニングするために、以下のガイドのいずれかに従ってください：

- **（推奨）** [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)
- （近日公開！）CDK

