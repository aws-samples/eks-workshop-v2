---
title: クリーンアップ
sidebar_position: 90
tmdTranslationSourceHash: b50eea77a7ff66e51772b8b1062a1d97
---

:::caution

次に進む前に、EKSクラスターをプロビジョニングするために使用したメカニズムに応じたクリーンアップ手順を実行してください：

- [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)

:::

このセクションでは、実習に使用したIDEをクリーンアップする方法を説明します。

まず、CloudFormationスタックをデプロイしたリージョンでCloudShellを開きます：

<ConsoleButton url="https://console.aws.amazon.com/cloudshell/home" service="console" label="Open CloudShell"/>

次に、以下のコマンドを実行してCloudFormationスタックを削除します：

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```

スタックが削除されると、IDEに関連するすべてのリソースがAWSアカウントから削除され、それ以上の料金が発生することはありません。
