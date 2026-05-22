---
title: アプリケーションアーキテクチャ
sidebar_position: 10
tmdTranslationSourceHash: '17e4cc9815c4309693f27a2a653bb847'
---

このワークショップのほとんどのラボでは、共通のサンプルアプリケーションを使用して、演習中に作業できる実際のコンテナコンポーネントを提供します。サンプルアプリケーションは、顧客がカタログを閲覧し、カートにアイテムを追加し、チェックアウトプロセスを通じて注文を完了できるシンプルなウェブストアアプリケーションをモデル化しています。

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

このアプリケーションには、いくつかのコンポーネントと依存関係があります：

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

| コンポーネント | 説明 |
| --------- | ----------- |
| UI | フロントエンドのユーザーインターフェースを提供し、他のさまざまなサービスへのAPIコールを集約します。 |
| Catalog | 商品リストと詳細のAPIです |
| Cart | 顧客のショッピングカートのAPIです |
| Checkout | チェックアウトプロセスを調整するAPIです |
| Orders | 顧客の注文を受け取り処理するAPIです |

最初は、ロードバランサーやマネージドデータベースなどのAWSサービスを使用せず、Amazon EKSクラスター内で自己完結する方法でアプリケーションをデプロイします。ラボを進めるうちに、EKSのさまざまな機能を活用して、小売店舗のためにより広範なAWSサービスと機能を活用していきます。

サンプルアプリケーションの完全なソースコードは[GitHub](https://github.com/aws-containers/retail-store-sample-app)で確認できます。

## コンテナイメージ

各コンポーネントはコンテナイメージとしてパッケージ化され、Amazon ECR Publicに公開されています：

| コンポーネント | ECR Publicリポジトリ | Dockerfile |
| --------- | --------------------- | ---------- |
| UI | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/Dockerfile) |
| Catalog | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/catalog/Dockerfile) |
| Cart | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/cart/Dockerfile) |
| Checkout | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/checkout/Dockerfile) |
| Orders | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/orders/Dockerfile) |

## Kubernetesアーキテクチャ

**catalog**コンポーネントがKubernetesリソースにどのようにマッピングされるかを見てみましょう：

<img src={require('@site/static/img/fastpaths/getting-started/catalog-microservice.webp').default} style={{width: '600px'}} />

この図では、考慮すべき点がいくつかあります：

- catalog APIを提供するアプリケーションは[Pod](https://kubernetes.io/docs/concepts/workloads/pods/)として実行されます。これはKubernetesで最も小さなデプロイ可能な単位です。アプリケーションPodは、前のセクションで概説したコンテナイメージを実行します。
- catalogコンポーネントに対して実行されるPodは、[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)によって作成され、catalog Podの1つ以上の「レプリカ」を管理して、水平方向にスケールできるようにします。
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)は、Podのセットとして実行されているアプリケーションを公開する抽象的な方法であり、これによりcatalog APIがKubernetesクラスター内の他のコンポーネントから呼び出されることを可能にします。各ServiceにはそれぞれのDNSエントリが与えられます。
- このワークショップの開始時には、Kubernetesクラスター内で[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)として実行されるMySQLデータベースがあります。これはステートフルなワークロードを管理するために設計されています。
- これらのKubernetesコンストラクトはすべて、専用のcatalog Namespaceにグループ化されています。各アプリケーションコンポーネントには独自のNamespaceがあります。

マイクロサービスアーキテクチャの各コンポーネントは、概念的にcatalogと似ており、Deploymentsを使用してアプリケーションワークロードPodを管理し、Servicesを使用してそれらのPodにトラフィックをルーティングします。アーキテクチャの広範なビューを拡張すると、システム全体でトラフィックがどのようにルーティングされるかを考えることができます：

<img src={require('@site/static/img/fastpaths/getting-started/microservices.webp').default} style={{width: '600px'}} />

**ui**コンポーネントは、たとえばユーザーのブラウザからHTTPリクエストを受け取ります。次に、アーキテクチャ内の他のAPIコンポーネントにHTTPリクエストを行ってそのリクエストを満たし、ユーザーにレスポンスを返します。各ダウンストリームコンポーネントは、独自のデータストアまたは他のインフラストラクチャを持つことができます。Namespaceは各マイクロサービスのリソースの論理的なグループ化であり、ソフトな分離境界としても機能し、Kubernetes RBACとNetwork Policiesを使用して効果的にコントロールを実装するために使用できます。

