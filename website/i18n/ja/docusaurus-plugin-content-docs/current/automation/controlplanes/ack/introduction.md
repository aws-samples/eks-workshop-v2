---
title: "はじめに"
sidebar_position: 3
tmdTranslationSourceHash: c50b1ee6030afba367dfa41a583f4641
---

従来、ACK を使用するには、AWS サービスごとにサービスコントローラーをご自身でインストールして運用する必要がありました。たとえば、Helm チャートとコンテナイメージをクラスターにデプロイし、その後継続的にパッチ適用やアップグレードを行います。各 ACK サービスコントローラーは、パブリックリポジトリで公開されている個別のコンテナイメージとしてパッケージ化されています。ACK の Helm チャートと公式コンテナイメージは[こちら](https://gallery.ecr.aws/aws-controllers-k8s)で入手できます。

代わりに、このラボでは [Amazon EKS ケイパビリティ](https://docs.aws.amazon.com/eks/latest/userguide/capabilities.html) を使用して、ACK をフルマネージドのケイパビリティとして提供します。このアプローチには次の特徴があります：

- ACK コントローラーは、クラスターのコンピューティングリソースを消費する代わりに、AWS マネージドインフラストラクチャ上で実行されます
- AWS がコントローラーのインストール、パッチ適用、アップグレード、可用性を管理します
- ケイパビリティは専用の IAM ケイパビリティロールを引き受けるため、コントローラー用に IRSA を構成する必要はありません
- 同じ ACK カスタムリソースと `kubectl` ワークフローを引き続き使用できます

Amazon DynamoDB 用の ACK ケイパビリティは、環境を準備した際にすでに有効化されているため、インストールするものはありません。ケイパビリティがアクティブであることを確認しましょう：

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_NAME \
  --capability-name ack-dynamodb \
  --query 'capability.status' --output text
ACTIVE
```

コントローラーはフルマネージドであるため、クラスター内にコントローラーのデプロイメントは実行されません。次のセクションでその仕組みを詳しく見ていきます。
