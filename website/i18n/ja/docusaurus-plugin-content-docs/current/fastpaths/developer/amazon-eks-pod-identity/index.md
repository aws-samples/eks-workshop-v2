---
title: "ワークロードからAWS APIへの安全なアクセス"
sidebar_position: 50
description: "EKS Pod Identityを使用して、Amazon Elastic Kubernetes Serviceで実行されているアプリケーションのAWS認証情報を管理します。"
tmdTranslationSourceHash: '77eb8e7949428f93ddc8daaf7676b48e'
---

:::tip 事前にセットアップされている内容
Amazon EKS Auto Modeクラスターには以下が含まれています：

- cartsサービス用のAmazon DynamoDBテーブル
- cartsワークロードがDynamoDBにアクセスするために設定されたIAMロール

:::

Pod内のコンテナで実行されるアプリケーションは、サポートされているAWS SDKまたはAWS CLIを使用して、AWS Identity and Access Management（IAM）権限を使ってAWSサービスにAPIリクエストを行うことができます。例えば、アプリケーションはS3バケットにファイルをアップロードしたり、DynamoDBテーブルにクエリを実行したりする必要がある場合があります。そのためには、AWS APIリクエストにAWS認証情報で署名する必要があります。[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)は、Amazon EC2インスタンスプロファイルがインスタンスに認証情報を提供するのと同様に、アプリケーションの認証情報を管理する機能を提供します。AWS認証情報を作成してコンテナに配布したり、Amazon EC2インスタンスのロールを使用する代わりに、IAMロールをKubernetes Service Accountに関連付けて、Podがそれを使用するように設定できます。サポートされているSDKバージョンの正確なリストについては、EKSドキュメントを[こちら](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html)で確認してください。

このモジュールでは、サンプルアプリケーションのコンポーネントの1つを再設定してAWS APIを活用し、適切な権限を提供します。

