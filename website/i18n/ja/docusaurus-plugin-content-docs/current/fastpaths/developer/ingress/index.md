---
title: "Ingress でワークロードを公開する"
chapter: true
sidebar_position: 20
description: "Amazon Elastic Kubernetes Service の Ingress API を使用して、HTTP および HTTPS ルートを外部に公開します。"
tmdTranslationSourceHash: "2a7c7a0a3e458f2a3b85abd264fa6c6a"
---

:::tip 事前にセットアップされているもの
Amazon EKS Auto Mode クラスターには、Kubernetes Ingress リソース用の AWS Elastic Load Balancer を管理する **AWS Load Balancer Controller** が含まれています。
:::

現在、ウェブストアアプリケーションは外部に公開されていないため、ユーザーがアクセスする方法がありません。ウェブストアワークロードには多くのマイクロサービスがありますが、エンドユーザーが利用できる必要があるのは `ui` アプリケーションのみです。これは、`ui` アプリケーションが内部の Kubernetes ネットワークを使用して、他のバックエンドサービスへのすべての通信を実行するためです。

Kubernetes Ingress は、クラスター内で実行されている Kubernetes サービスへの外部または内部の HTTP(S) アクセスを管理できる API リソースです。Amazon Elastic Load Balancing Application Load Balancer (ALB) は、リージョン内の複数のターゲット（Amazon EC2 インスタンスなど）にわたってアプリケーション層（レイヤー 7）で受信トラフィックを負荷分散する人気の AWS サービスです。ALB は、ホストまたはパスベースのルーティング、TLS（Transport Layer Security）終端、WebSockets、HTTP/2、AWS WAF（Web Application Firewall）統合、統合アクセスログ、ヘルスチェックなど、多くの機能をサポートしています。

このラボ演習では、Kubernetes Ingress モデルで ALB を使用して、サンプルアプリケーションを公開します。

