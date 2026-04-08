---
title: コンポーネントのパッケージング
sidebar_position: 20
tmdTranslationSourceHash: 48eb52800a66944b2465d3a51197051c
---

ワークロードをEKSなどのKubernetesディストリビューションにデプロイする前に、まずコンテナイメージとしてパッケージ化し、コンテナレジストリに公開する必要があります。このようなコンテナの基本的なトピックはこのワークショップでは扱いませんが、サンプルアプリケーションのコンテナイメージは今日のラボで使用するために、Amazon Elastic Container Registryですでに利用可能になっています。

以下の表は各コンポーネントのECR Publicリポジトリへのリンクと、各コンポーネントのビルドに使用された`Dockerfile`へのリンクを提供しています。

| コンポーネント     | ECR Publicリポジトリ                                                              | Dockerfile                                                                                                  |
| ------------------ | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| UI                 | [リポジトリ](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)       | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/Dockerfile)       |
| カタログ           | [リポジトリ](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog)  | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/catalog/Dockerfile)  |
| ショッピングカート | [リポジトリ](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart)     | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/cart/Dockerfile)     |
| チェックアウト     | [リポジトリ](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/checkout/Dockerfile) |
| 注文               | [リポジトリ](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders)   | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/orders/Dockerfile)   |
