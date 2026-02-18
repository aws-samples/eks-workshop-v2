---
title: "アドオン"
sidebar_position: 20
tmdTranslationSourceHash: e8980a5b478431de18d3b9ead0981b91
---

EKSアドオンを使用すると、Kubernetesアプリケーションをサポートする主要な機能を提供する運用ソフトウェア、つまりアドオンの設定、デプロイ、更新を行うことができます。これらのアドオンには、Amazon VPC CNIなどのクラスターネットワーク用の重要なツールや、オブザーバビリティ、管理、スケーリング、セキュリティのための運用ソフトウェアが含まれます。アドオンは基本的に、Kubernetesアプリケーションの運用をサポートするソフトウェアであり、アプリケーション自体に特化したものではありません。

**[Amazon EKSアドオン](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)** は、Amazon EKSクラスター向けに厳選されたアドオンセットのインストールと管理を提供します。すべてのAmazon EKSアドオンには、最新のセキュリティパッチ、バグ修正が含まれており、Amazon EKSとの連携が検証されています。Amazon EKSアドオンを使用すると、Amazon EKSクラスターが安全で安定していることを一貫して確保でき、アドオンのインストール、設定、更新に必要な作業量を削減できます。

Amazon EKSアドオンは、Amazon EKS API、AWS Management Console、AWS CLI、およびeksctlを使用して追加、更新、削除できます。また、[Amazon EKSアドオンの作成](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/amazon-eks-addons/)も可能です。Amazon EKSアドオン実装は汎用的で、EKS APIでサポートされているあらゆるアドオンのデプロイに使用できます。ネイティブEKSアドオンまたはAWS Marketplaceから提供されるサードパーティのアドオンのいずれも利用可能です。

**Add-ons**タブに移動すると、すでにインストールされているアドオンを検索できます。

![Insights](/img/resource-view/find-add-ons.jpg)

または「Get more add-ons」から追加のアドオンを選択したり、クラスターを強化するためのAWS MarketPlaceアドオンを検索したりできます。

![Insights](/img/resource-view/select-add-ons.jpg)
