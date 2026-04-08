---
title: "IAM Roles for Service Accounts"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Manage AWS credentials for your applications running on Amazon Elastic Kubernetes Service with IAM Roles for Service Accounts."
tmdTranslationSourceHash: 315131c1bce2a477ebe6a119db922ace
---

::required-time

:::tip 開始する前に
このセクションのために環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment security/irsa
```

これにより、ラボ環境に次の変更が適用されます：

- Amazon DynamoDBテーブルの作成
- DynamoDBテーブルにアクセスするためのAmazon EKSワークロード用IAMロールの作成
- Amazon EKSクラスターへのAWS Load Balancer Controllerのインストール

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/irsa/.workshop/terraform)で確認できます。

:::

ポッド内のコンテナ内のアプリケーションは、AWS SDKまたはAWS CLIを使用して、AWS Identity and Access Management（IAM）権限を使用してAWSサービスにAPIリクエストを行うことができます。例えば、アプリケーションがS3バケットにファイルをアップロードしたり、DynamoDBテーブルをクエリしたりする必要がある場合があります。そのためには、アプリケーションはAWS認証情報を使ってAWS APIリクエストに署名する必要があります。[IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)（IRSA）は、IAMインスタンスプロファイルがAmazon EC2インスタンスに認証情報を提供するのと同様の方法で、アプリケーションの認証情報を管理する機能を提供します。AWS認証情報をコンテナに作成して配布したり、Amazon EC2インスタンスプロファイルに認証を依存したりする代わりに、KubernetesのServiceAccountにIAMロールを関連付け、ポッドがそのServiceAccountを使用するように設定します。

この章では、サンプルアプリケーションのコンポーネントの1つを再構成して、AWS APIを活用し、適切な認証を提供します。
