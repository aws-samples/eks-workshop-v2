---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で Ingress API を使用して、外部世界に HTTP および HTTPS ルートを公開します。"
tmdTranslationSourceHash: 72d939af908c33198aba9c59be5e701d
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください:

```bash timeout=300 wait=30
$ prepare-environment exposing/ingress
```

これにより、ラボ環境に以下の変更が加えられます:

- AWS Load Balancer Controller に必要な IAM ロールを作成
- ExternalDNS に必要な IAM ロールを作成
- AWS Route 53 プライベートホストゾーンの作成

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/ingress/.workshop/terraform)で確認できます。

:::

Kubernetes Ingress は、クラスターで実行されている Kubernetes サービスへの外部または内部 HTTP(S) アクセスを管理できる API リソースです。Amazon Elastic Load Balancing Application Load Balancer (ALB) は、アプリケーション層（レイヤー 7）でリージョン内の複数のターゲット（Amazon EC2 インスタンスなど）間で受信トラフィックをロードバランスする一般的な AWS サービスです。ALB は、ホストまたはパスベースのルーティング、TLS（Transport Layer Security）ターミネーション、WebSockets、HTTP/2、AWS WAF（Web Application Firewall）統合、統合されたアクセスログ、およびヘルスチェックなど、複数の機能をサポートしています。

この演習では、Kubernetes ingress モデルを使用して ALB でサンプルアプリケーションを公開します。
