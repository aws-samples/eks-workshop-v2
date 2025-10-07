---
title: "紹介"
sidebar_position: 21
kiteTranslationSourceHash: f891bd52e91f7dbf2c8700666e52da5e
---

アーキテクチャの `carts` コンポーネントはストレージバックエンドとしてAmazon DynamoDBを使用しています。これは、Amazon EKSとの非リレーショナルデータベース統合でよく見られるユースケースです。現在デプロイされているcarts APIの方法では、EKSクラスタ内でコンテナとして実行されている[Amazon DynamoDBの軽量バージョン](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)を使用しています。

次のコマンドを実行して確認できます：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

上記の例では、Pod `carts-dynamodb-698674dcc6-hw2bg` が軽量DynamoDBサービスです。`carts` アプリケーションがこれを使用していることを環境を調査して確認できます：

```bash
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

このアプローチはテストには便利ですが、スケールと信頼性の利点を最大限に活用するために、フルマネージドのAmazon DynamoDBサービスを使用するようにアプリケーションを移行したいと思います。
