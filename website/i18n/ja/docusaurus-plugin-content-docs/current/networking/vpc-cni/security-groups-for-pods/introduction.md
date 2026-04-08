---
title: "Introduction"
sidebar_position: 10
tmdTranslationSourceHash: 5d5cdf0aa50b19d179ab2651fb0e3e11
---

アーキテクチャの `catalog` コンポーネントは、ストレージバックエンドとしてMySQL データベースを使用しています。現在、カタログAPIはEKSクラスター内でPodとして実行されているデータベースとともにデプロイされています。

以下のコマンドを実行して確認できます：

```bash
$ kubectl -n catalog get pod
NAME                                READY   STATUS    RESTARTS        AGE
catalog-5d7fc9d8f-xm4hs             1/1     Running   0               14m
catalog-mysql-0                     1/1     Running   0               14m
```

上記の出力では、Pod `catalog-mysql-0` がMySQL データベースです。`catalog` アプリケーションがこれを使用していることを環境を調査することで確認できます：

```bash
$ kubectl -n catalog exec deployment/catalog -- env \
  | grep RETAIL_CATALOG_PERSISTENCE_ENDPOINT
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
```

私たちはアプリケーションを完全マネージド型のAmazon RDSサービスに移行して、そのスケールと信頼性の機能を活用したいと考えています。
