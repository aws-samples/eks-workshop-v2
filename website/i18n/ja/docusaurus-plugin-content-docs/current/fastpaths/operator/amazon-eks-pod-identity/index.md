---
title: "ワークロードからAWS APIへの安全なアクセス"
sidebar_position: 60
description: "EKS Pod Identityを使用して、Amazon Elastic Kubernetes Service上で実行されているアプリケーションのAWS認証情報を管理します。"
tmdTranslationSourceHash: '77cff549fe1a20bbfaf0bb39b74c9e8a'
---

:::tip セットアップ済みの内容
Amazon EKS Auto Modeクラスターには以下が含まれています：

- cartsサービス用のAmazon DynamoDBテーブル
- cartsワークロードがDynamoDBにアクセスするために設定されたIAMロール

:::

Pod内のコンテナのアプリケーションは、サポートされているAWS SDKまたはAWS CLIを使用して、AWS Identity and Access Management（IAM）権限を使ってAWSサービスへのAPIリクエストを行うことができます。たとえば、アプリケーションがS3バケットにファイルをアップロードしたり、DynamoDBテーブルをクエリしたりする必要がある場合、AWS APIリクエストにAWS認証情報で署名する必要があります。[EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)は、Amazon EC2インスタンスプロファイルがインスタンスに認証情報を提供する方法と同様に、アプリケーションの認証情報を管理する機能を提供します。AWS認証情報を作成してコンテナに配布したり、Amazon EC2インスタンスのロールを使用したりする代わりに、IAMロールをKubernetes Service Accountに関連付けて、Podがそれを使用するように設定できます。サポートされているSDKバージョンの正確なリストについては、EKSドキュメントを[こちら](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html)で確認してください。

このモジュールでは、サンプルアプリケーションのコンポーネントの1つを再設定してAWS APIを活用し、適切な権限を提供します。

