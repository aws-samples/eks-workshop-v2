---
title: "AWS Gateway API コントローラー"
sidebar_position: 10
tmdTranslationSourceHash: c80632213a6b836924dc5324f797c745
---

Gateway API は、Kubernetes ネットワーキングコミュニティによって管理されているオープンソースプロジェクトです。これは Kubernetes におけるアプリケーションネットワーキングをモデル化するリソースのコレクションです。Gateway API は、GatewayClass、Gateway、Route などのリソースをサポートしており、多くのベンダーによって実装され、業界全体で広くサポートされています。

元々は広く知られている Ingress API の後継として考案されたもので、Gateway API の利点には、多くの一般的に使用されているネットワークプロトコルの明示的なサポート、およびトランスポート層セキュリティ（TLS）との緊密に統合されたサポートなどが含まれます（ただしこれらに限定されません）。

AWS では、AWS Gateway API コントローラーを使用して Gateway API を Amazon VPC Lattice と統合しています。このコントローラーをクラスターにインストールすると、ゲートウェイやルートなどの Gateway API リソースの作成を監視し、以下の図のマッピングに従って対応する Amazon VPC Lattice オブジェクトをプロビジョニングします。AWS Gateway API コントローラーはオープンソースプロジェクトであり、Amazon によって完全にサポートされています。

![Kubernetes Gateway API オブジェクトと VPC Lattice コンポーネント](/docs/networking/vpc-lattice/fundamentals-mapping.webp)

図に示すように、Kubernetes Gateway API にはさまざまなレベルの制御に関連する異なるペルソナがあります：

- インフラストラクチャプロバイダー：VPC Lattice を GatewayClass として識別する Kubernetes `GatewayClass` を作成します。
- クラスターオペレーター：サービスネットワークに関連する VPC Lattice からの情報を取得する Kubernetes `Gateway` を作成します。
- アプリケーション開発者：ゲートウェイからバックエンド Kubernetes サービスにトラフィックをリダイレクトする方法を指定する `HTTPRoute` オブジェクトを作成します。

AWS Gateway API コントローラーは Amazon VPC Lattice と統合し、以下のことを可能にします：

- VPC やアカウント間のサービス間のネットワーク接続をシームレスに処理します。
- 複数の Kubernetes クラスターにまたがるこれらのサービスを発見します。
- これらのサービス間の通信を保護するための多層防御戦略を実装します。
- サービス間のリクエスト/レスポンストラフィックを観察します。

この章では、`checkout` マイクロサービスの新しいバージョンを作成し、Amazon VPC Lattice を使用してシームレスに A/B テストを実行します。

