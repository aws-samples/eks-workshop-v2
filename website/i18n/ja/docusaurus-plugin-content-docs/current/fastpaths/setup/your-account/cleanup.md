---
title: クリーンアップ
sidebar_position: 90
tmdTranslationSourceHash: 'b50eea77a7ff66e51772b8b1062a1d97'
---

:::caution

先に進む前に、ラボ用 EKS クラスターのプロビジョニングに使用したメカニズムに応じて、それぞれのクリーンアップ手順を実行していることを確認してください：

- [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)

:::

このセクションでは、ラボの実行に使用した IDE のクリーンアップ方法について説明します。

まず、CloudFormation スタックをデプロイしたリージョンで CloudShell を開きます：

<ConsoleButton url="https://console.aws.amazon.com/cloudshell/home" service="console" label="CloudShell を開く"/>

次に、以下のコマンドを実行して CloudFormation スタックを削除します：

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```

スタックが削除されると、IDE に関連するすべてのリソースが AWS アカウントから削除され、今後の課金が防止されます。

