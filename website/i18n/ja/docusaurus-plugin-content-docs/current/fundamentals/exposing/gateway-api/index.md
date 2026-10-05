---
title: "Gateway API"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で Gateway API を使用して Kubernetes サービスへのトラフィックを公開およびルーティングします。"
tmdTranslationSourceHash: '338809b8f6eb03de5933e964f77ac9a0'
---

::required-time

:::tip 始める前に
このセクションに向けて環境を準備します:

```bash timeout=300 wait=30
$ prepare-environment exposing/gateway-api
```

これにより、ラボ環境に以下の変更が加えられます:

- Gateway API CRD (Custom Resource Definition) のインストール
- AWS Load Balancer Controller Gateway API CRD のインストール
- AWS Load Balancer Controller 用の IAM role の作成

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/gateway-api/.workshop/terraform)で確認できます。

:::

[Gateway API](https://gateway-api.sigs.k8s.io/) は Kubernetes Ingress API の後継であり、クラスタへのトラフィックルーティングを管理するためのより表現力豊かで拡張可能なモデルを提供します。インフラストラクチャとルーティングの関心事を単一のリソースに結合する Ingress とは異なり、Gateway API は責任を分離するロール指向の設計を使用します:

- **GatewayClass** — コントローラを定義します（インフラストラクチャプロバイダーが管理）
- **Gateway** — ロードバランサーインフラストラクチャをプロビジョニングします（クラスタオペレーターが管理）
- **HTTPRoute** — バックエンドサービスへのルーティングルールを定義します（アプリケーション開発者が管理）

この分離により、異なるチームが独立して自分たちのリソースを管理でき、セキュリティと運用の明確性が向上します。

このモジュールでは、AWS Load Balancer Controller で Gateway API を使用して、サンプルアプリケーションへのトラフィックを公開およびルーティングする方法を探ります。以下の 3 つの主要なシナリオを取り上げます:

1. **UI の公開** — GatewayClass、Gateway、HTTPRoute を作成して ALB をプロビジョニングし、UI サービスへのトラフィックをルーティングします
2. **パスベースルーティング** — Catalog API 用の 2 番目の HTTPRoute を追加し、複数のサービスが単一の Gateway（および ALB）をクロス namespace ルーティングで共有する方法を示します
3. **Canary Deployment** — 重み付けされたトラフィック分割を使用して、UI のあるバージョンから別のバージョンへ段階的にトラフィックをシフトします

