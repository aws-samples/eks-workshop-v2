---
title: "Amazon VPC CNI"
sidebar_position: 3
chapter: true
weight: 20
tmdTranslationSourceHash: ba7a4eda2f22a760ef6a61b4def4fae1
---

Pod ネットワーキング、またはクラスターネットワーキングは、Kubernetes ネットワーキングの中心です。Kubernetes はクラスターネットワーキングに Container Network Interface (CNI) プラグインをサポートしています。

ネットワーキングモジュールのビデオウォークスルーを、モジュールのメンテナーの一人である Sheetal Joshi (AWS) が解説しています：

<ReactPlayer controls src="https://www.youtube-nocookie.com/embed/EAZnXII9NTY" width={640} height={360} /> <br />

Amazon EKS は、ワーカーノードと Kubernetes Pod にネットワーク機能を提供するために Amazon VPC を使用しています。EKS クラスターは2つの VPC で構成されています：Kubernetes コントロールプレーンをホストする AWS 管理 VPC と、コンテナが実行される Kubernetes ワーカーノードおよびクラスターで使用される他の AWS インフラストラクチャ（ロードバランサーなど）をホストするカスタマー管理 VPC です。すべてのワーカーノードは、マネージド API サーバーエンドポイントに接続する能力が必要です。この接続により、ワーカーノードは Kubernetes コントロールプレーンに自身を登録し、アプリケーションポッドを実行するリクエストを受け取ることができます。

ワーカーノードは、EKS パブリックエンドポイントまたは EKS 管理の Elastic Network Interface (ENI) を通じて EKS コントロールプレーンに接続します。クラスター作成時に渡すサブネットは、EKS がこれらの ENI を配置する場所に影響します。少なくとも 2 つのアベイラビリティーゾーンに 2 つのサブネットを提供する必要があります。ワーカーノードが接続する経路は、クラスターのプライベートエンドポイントを有効または無効にしているかどうかによって決まります。EKS はワーカーノードと通信するために EKS 管理の ENI を使用します。

Amazon EKS は公式に、Kubernetes Pod ネットワーキングを実装するための Amazon Virtual Private Cloud (VPC) CNI プラグインをサポートしています。VPC CNI は AWS VPC とネイティブに統合され、アンダーレイモードで動作します。アンダーレイモードでは、Pod とホストは同じネットワーク層に配置され、ネットワーク名前空間を共有します。Pod の IP アドレスはクラスターと VPC の観点から一貫しています。
