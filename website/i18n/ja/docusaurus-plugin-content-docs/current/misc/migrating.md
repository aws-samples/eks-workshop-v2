---
title: レガシー・ラボ環境の移行
tmdTranslationSourceHash: 14050535b3534184f1640b7b062812cc
---

2023年7月21日、EKSワークショップはインフラストラクチャの提供方法に関する大きな変更が行われました。以前はワークショップはすべてのインフラストラクチャを事前にTerraformを使って提供していましたが、開始時に発生する可能性のある問題の数を減らすために変更を行うことが決定されました。ワークショップのインフラストラクチャは現在、段階的に構築され、より簡素化された初期設定になっています。

Terraformに基づく従来のメカニズムで提供されたラボ環境がある場合は、この新しい提供メカニズムに移行する必要があります。以下の手順では、既存の環境をクリーンアップするためのガイドを提供します。

まず、Cloud9 IDEにアクセスし、以下を実行してクラスターで実行されているサンプルアプリケーションをクリーンアップします。これはTerraformがEKSクラスターとVPCをクリーンアップできるようにするために必要です：

```bash test=false
$ delete-environment
```

次に、TerraformによってプロビジョニングされたAWSリソースを削除する必要があります。最初にクローンしたGitリポジトリ（例えば、ローカルマシン上）から次のコマンドを実行します：

```bash test=false
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
# To delete the descheduler add-on, run the following command:
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
# To delete the core blueprints add-ons, run the following command:
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
# To delete the remaining resources created by Terraform, run the following command:
$ terraform destroy --auto-approve
```

これで、[ここに概説されている手順](/docs/introduction/setup/your-account)に従って、新しいラボ環境を作成できます。
