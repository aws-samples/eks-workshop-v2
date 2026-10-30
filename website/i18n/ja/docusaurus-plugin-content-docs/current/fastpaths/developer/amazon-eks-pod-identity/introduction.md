---
title: "はじめに"
sidebar_position: 31
tmdTranslationSourceHash: '30a2bf69cd7c96a2fc73a4005d5069f1'
---

アーキテクチャの `carts` コンポーネントは、ストレージバックエンドとして Amazon DynamoDB を使用しています。これは、Amazon EKS との非リレーショナルデータベース統合でよく見られるユースケースです。現在、carts API は、EKS クラスタ内のコンテナとして実行されている [Amazon DynamoDB の軽量版](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) と共にデプロイされています。

次のコマンドを実行すると、これを確認できます：

```bash wait=30
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

上記の出力では、Pod `carts-dynamodb-698674dcc6-hw2bg` が軽量版 DynamoDB サービスです。環境変数を確認することで、`carts` アプリケーションがこれを使用していることを検証できます：

```bash timeout=180
$ kubectl wait --for=condition=Ready pods -l app.kubernetes.io/component=service -n carts --timeout=120s
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

このアプローチはテストには便利ですが、フルマネージドの Amazon DynamoDB サービスが提供するスケールと信頼性を最大限に活用するために、アプリケーションを移行したいと考えています。次のセクションでは、Amazon DynamoDB を使用するようにアプリケーションを再構成し、EKS Pod Identity を実装して AWS サービスへの安全なアクセスを提供します。

