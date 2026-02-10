---
title: "Amazon VPC Lattice"
sidebar_position: 40
weight: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでのAmazon VPC Latticeによるサービス間接続、セキュリティ、モニタリングの簡素化。"
tmdTranslationSourceHash: f84f9d92b7355003e2ef753ad8c7d433
---

::required-time

:::caution プレビュー

このモジュールは現在プレビュー段階です。問題が発生した場合は[報告](https://github.com/aws-samples/eks-workshop-v2/issues)してください。

:::

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment networking/vpc-lattice
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS APIにアクセスするためのGateway APIコントローラー用のIAMロールを作成
- Amazon EKSクラスターにAWS Load Balancer Controllerをインストール

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/vpc-lattice/.workshop/terraform)で確認できます。

:::

[Amazon VPC Lattice](https://aws.amazon.com/vpc/lattice/)は、ネットワークの専門知識がなくても、サービス間通信の接続、保護、監視を一貫した方法で行うことができるアプリケーション層のネットワーキングサービスです。VPC Latticeを使用すると、Kubernetesクラスターを含む基盤となるコンピューティングタイプに関係なく、VPC間やアカウント間でのサービス間通信を可能にするネットワークアクセス、トラフィック管理、ネットワークモニタリングを一貫して設定できます。

Amazon VPC Latticeは、コンポーネントの検出、個々のワークロード間のトラフィックルーティング、アクセス認可などの一般的なネットワーキングタスクを処理し、開発者が追加のソフトウェアやコードを通じてこれらを自分で行う必要性を排除します。数回のクリックまたはAPIコールで、開発者はネットワークの専門知識がなくても、アプリケーションがどのように通信すべきかを定義するポリシーを設定できます。

Latticeを使用する主な利点は以下の通りです：

- **開発者の生産性向上**：Latticeは、開発者がビジネスに重要な機能の構築に集中できるようにし、ネットワーキング、セキュリティ、可観測性の課題をすべてのコンピューティングプラットフォームで統一的に処理します
- **セキュリティ体制の向上**：Latticeにより、開発者は現在のメカニズム（例：証明書管理）の運用上の負担なしに、アプリケーション間の通信を簡単に認証し保護できます。Latticeアクセスポリシーにより、開発者とクラウド管理者は詳細なアクセス制御を強制できます。また、Latticeはトラフィックの転送中の暗号化を強制し、セキュリティ体制をさらに向上させることができます
- **アプリケーションの拡張性と回復力の向上**：Latticeにより、豊富なルーティング、認証、認可、モニタリングなどを備えたデプロイされたアプリケーションのネットワークを簡単に作成できます。Latticeはワークロードにリソースのオーバーヘッドをかけずにこれらの利点を提供し、大規模なデプロイメントや毎秒多数のリクエストを、重大な遅延を追加することなくサポートできます
- **異種インフラストラクチャによるデプロイメントの柔軟性**：LatticeはすべてのコンピューティングサービスーEC2、ECS、EKS、Lambdaーにわたって一貫した機能を提供し、オンプレミスに存在するサービスも含めることができ、組織がユースケースに最適なコンピューティングインフラストラクチャを選択する柔軟性を提供します。

Amazon VPC Latticeの[コンポーネント](https://docs.aws.amazon.com/vpc-lattice/latest/ug/what-is-vpc-service-network.html#vpc-service-network-components-overview)には以下が含まれます：

- **サービスネットワーク**：
  サービスとポリシーを含む共有可能な管理された論理的なグループ。

- **サービス**：
  DNS名を持つアプリケーションユニットを表し、すべてのコンピューティングーインスタンス、コンテナ、サーバーレスーにわたって拡張できます。リスナー、ターゲットグループ、ターゲットで構成されています。

- **サービスディレクトリ**：
  AWSアカウント内のレジストリで、バージョン別のサービスとそのDNS名のグローバルビューを保持しています。

- **セキュリティポリシー**：
  サービスがどのように通信することを許可されるかを決定する宣言型ポリシー。これらはサービスレベルまたはサービスネットワークレベルで定義できます。

![Amazon VPC Latticeのコンポーネント](/docs/networking/vpc-lattice/vpc_lattice_building_blocks.webp)

