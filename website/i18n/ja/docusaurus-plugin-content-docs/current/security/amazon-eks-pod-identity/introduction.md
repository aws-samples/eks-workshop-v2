---
title: "Introduction"
sidebar_position: 31
kiteTranslationSourceHash: c68e095ef9e36a70423411002c0c5401
---

私たちのアーキテクチャの`carts`コンポーネントは、ストレージバックエンドとしてAmazon DynamoDBを使用しています。これは、Amazon EKSとの非リレーショナルデータベース統合でよく見られるユースケースです。現在、carts APIは、EKSクラスタ内でコンテナとして実行されている[Amazon DynamoDBの軽量バージョン](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)を使用してデプロイされています。

以下のコマンドを実行して、これを確認できます：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

上記の出力では、Pod `carts-dynamodb-698674dcc6-hw2bg`が軽量DynamoDBサービスです。`carts`アプリケーションがこれを使用していることを、その環境を調査することで確認できます：

```bash
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

このアプローチはテストには役立ちますが、私たちはアプリケーションをフルマネージドのAmazon DynamoDBサービスに移行して、そのスケールと信頼性を最大限に活用したいと考えています。次のセクションでは、アプリケーションをAmazon DynamoDBを使用するように再構成し、AWS サービスへの安全なアクセスを提供するためにEKS Pod Identityを実装します。
