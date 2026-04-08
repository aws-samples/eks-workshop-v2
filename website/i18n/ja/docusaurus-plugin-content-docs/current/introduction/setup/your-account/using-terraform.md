---
title: Terraformを使用する
sidebar_position: 30
tmdTranslationSourceHash: 0e3724e9afa0ee9b592cd183d26f5329
---

:::warning
Terraformを使用したワークショップクラスターの作成は現在プレビュー中です。発生した問題は[GitHubリポジトリ](https://github.com/aws-samples/eks-workshop-v2/issues)で報告してください。
:::

このセクションでは、[HashiCorp Terraform](https://developer.hashicorp.com/terraform)を使用して実習用クラスターを構築する方法を説明します。これはTerraformインフラストラクチャ・アズ・コードの使用に慣れている学習者を対象としています。

`terraform` CLIはIDE環境に事前にインストールされているため、すぐにクラスターを作成できます。クラスターとその支援インフラストラクチャを構築するために使用される主なTerraform設定ファイルを確認しましょう。

## Terraform設定ファイルについて

`providers.tf`ファイルはインフラストラクチャを構築するために必要なTerraformプロバイダーを設定します。このケースでは、`aws`、`kubernetes`、`helm`プロバイダーを使用します：

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

`main.tf`ファイルは、現在使用されているAWSアカウントとリージョンを取得するためのTerraformデータソースと、いくつかのデフォルトタグを設定します：

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

`vpc.tf`設定は、VPCインフラストラクチャが作成されることを保証します：

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

最後に、`eks.tf`ファイルはマネージドノードグループを含むEKSクラスター設定を指定します：

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Terraformでワークショップ環境を作成する

この設定に基づいて、Terraformは以下のワークショップ環境を作成します：

- 3つのアベイラビリティーゾーンにまたがるVPC
- EKSクラスター
- IAM OIDCプロバイダー
- `default`という名前のマネージドノードグループ
- プレフィックス委任を使用するように設定されたVPC CNI

Terraformファイルをダウンロードします：

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

以下のTerraformコマンドを実行して、ワークショップ環境をデプロイします：

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

このプロセスは通常、完了するまでに20〜25分かかります。

## 次のステップ

クラスターの準備ができたら、[ラボのナビゲーション](/docs/introduction/navigating-labs)セクションに進むか、トップナビゲーションバーを使用してワークショップの任意のモジュールに直接進んでください。ワークショップが完了したら、以下の手順に従って環境をクリーンアップしてください。

## クリーンアップ（ワークショップが終わったら実行するステップ）

:::warning
以下は、EKSクラスターの使用が終了した後、リソースをクリーンアップする方法を示しています。これらのステップを完了することで、AWSアカウントへのさらなる課金を防ぐことができます。
:::

IDE環境を削除する前に、前のステップでセットアップしたクラスターをクリーンアップします。

まず、`delete-environment`を使用して、サンプルアプリケーションと残っているラボのインフラストラクチャが削除されることを確認します：

```bash
$ delete-environment
```

次に、`terraform`を使用してクラスターを削除します：

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

これで[クリーンアップ](./cleanup.md)に進んでIDEを片付けることができます。
