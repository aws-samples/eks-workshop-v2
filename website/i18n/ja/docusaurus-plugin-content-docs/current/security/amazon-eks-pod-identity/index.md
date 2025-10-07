---
title: "Amazon EKS Pod Identity"
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでEKS Pod Identityを使用してアプリケーションのAWS認証情報を管理します。"
kiteTranslationSourceHash: eb2653bc6911d2ddc5130a39bfbf6fa2
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment security/eks-pod-identity
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon DynamoDBテーブルの作成
- DynamoDBテーブルにアクセスするためのAmazonEKSワークロード用IAMロールの作成
- Amazon EKSクラスターにAWS Load Balancer Controllerのインストール

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/eks-pod-identity/.workshop/terraform)で確認できます。

:::

PodのコンテナにあるアプリケーションはサポートされているAWS SDKまたはAWS CLIを使用して、AWS Identity and Access Management（IAM）権限を使用してAWSサービスにAPIリクエストを行うことができます。例えば、アプリケーションはS3バケットにファイルをアップロードしたり、DynamoDBテーブルを照会したりする必要があるかもしれません。そのためにはAWS APIリクエストにAWS認証情報で署名する必要があります。[EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)は、Amazon EC2インスタンスプロファイルがインスタンスに認証情報を提供するのと同様の方法で、アプリケーションの認証情報を管理する機能を提供します。AWS認証情報を作成してコンテナに配布したり、Amazon EC2インスタンスのロールを使用したりする代わりに、IAMロールをKubernetesのサービスアカウントに関連付け、Podがそれを使用するように設定できます。サポートされているSDKバージョンの正確なリストについては、[EKSドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html)をご確認ください。

このモジュールでは、サンプルアプリケーションコンポーネントの1つを再構成して、AWS APIを活用し、適切な権限を提供します。

