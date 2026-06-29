---
title: "はじめに"
sidebar_position: 31
tmdTranslationSourceHash: '30a2bf69cd7c96a2fc73a4005d5069f1'
---

アーキテクチャの`carts`コンポーネントは、Amazon DynamoDBをストレージバックエンドとして使用しています。これは、Amazon EKSとの非リレーショナルデータベース統合でよく見られるユースケースです。現在、carts APIは、EKSクラスター内のコンテナとして実行されている[Amazon DynamoDBの軽量版](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/DynamoDBLocal.html)でデプロイされています。

次のコマンドを実行すると、これを確認できます:

```bash wait=30
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

上記の出力では、Pod `carts-dynamodb-698674dcc6-hw2bg`が軽量DynamoDBサービスです。`carts`アプリケーションがこれを使用していることは、環境変数を確認することで検証できます:

```bash timeout=180
$ kubectl wait --for=condition=Ready pods -l app.kubernetes.io/component=service -n carts --timeout=120s
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

このアプローチはテストには便利ですが、フルマネージドなAmazon DynamoDBサービスを使用するようにアプリケーションを移行し、スケールと信頼性の利点を最大限に活用したいと考えています。以下のセクションでは、Amazon DynamoDBを使用するようにアプリケーションを再構成し、EKS Pod IdentityでAWSサービスへの安全なアクセスを実装します。

