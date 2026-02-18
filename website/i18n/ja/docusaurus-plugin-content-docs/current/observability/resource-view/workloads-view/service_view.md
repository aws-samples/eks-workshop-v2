---
title: "サービスとエンドポイント"
sidebar_position: 20
tmdTranslationSourceHash: a11c44ee0945ad6873bae46672cfbdb7
---

Kubernetes のサービスとネットワークリソースを表示するには、<i>リソース</i>タブをクリックします。<i>サービスとネットワーク</i>セクションにドリルダウンすると、サービスとネットワークの一部である Kubernetes API リソースタイプをいくつか表示できます。このラボ演習では、Pod のセットで実行されているアプリケーションを Service、Endpoints および Ingress として公開する方法について詳しく説明します。

[Service](https://kubernetes.io/docs/concepts/services-networking/service/) リソースビューは、クラスター内のポッドのセット上で実行されているアプリケーションを公開するすべてのサービスを表示します。

![Insights](/img/resource-view/service-view.jpg)

サービス <i>cart</i> を選択すると、Info セクションにセレクタ（サービスがターゲットとするポッドのセットは通常セレクタによって決定されます）、実行しているプロトコルとポート、およびラベルとアノテーションを含むサービスに関する詳細が表示されます。
ポッドはエンドポイントを通じてサービスに自身を公開します。エンドポイントは、ポッドの IP アドレスとポートが動的に割り当てられるリソースです。エンドポイントは Kubernetes サービスによって参照されます。

![Insights](/img/resource-view/service-endpoint.png)

このサンプルアプリケーションでは、<i>Endpoints</i> をクリックして、Info、Labels および Annotations セクションとともにエンドポイントに関連付けられている IP アドレスとポートの詳細を確認します。
