---
title: サンプルアプリケーション
sidebar_position: 10
kiteTranslationSourceHash: 583977cbf40b8bd4fc4e0c9fbe10215b
---

このワークショップのほとんどのラボでは、演習中に作業できる実際のコンテナコンポーネントを提供する共通のサンプルアプリケーションを使用しています。サンプルアプリケーションは、顧客が商品カタログを閲覧し、カートにアイテムを追加し、チェックアウトプロセスを通じて注文を完了できる単純なウェブストアをモデル化しています。

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

このアプリケーションにはいくつかのコンポーネントと依存関係があります：

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

| コンポーネント | 説明                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------- |
| UI             | フロントエンドユーザーインターフェイスを提供し、他のさまざまなサービスへのAPI呼び出しを集約します。 |
| Catalog        | 製品リストと詳細のAPI                                                                       |
| Cart           | 顧客のショッピングカートのAPI                                                               |
| Checkout       | チェックアウトプロセスを調整するAPI                                                         |
| Orders         | 顧客の注文を受け取り処理するAPI                                                             |

最初は、ロードバランサーやマネージドデータベースなどのAWSサービスを使用せず、Amazon EKSクラスター内で自己完結型のアプリケーションをデプロイします。ラボを進める過程で、EKSのさまざまな機能を活用して、リテールストアのためのより幅広いAWSサービスと機能を利用します。

サンプルアプリケーションの完全なソースコードは[GitHub](https://github.com/aws-containers/retail-store-sample-app)で見つけることができます。

