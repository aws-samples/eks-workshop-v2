---
title: "AWS Load Balancer Controller"
sidebar_position: 20
kiteTranslationSourceHash: 9f5f52ecf3d2d9d1653908f4b905b48e
---

**AWS Load Balancer Controller**は、Kubernetesクラスターの Elastic Load Balancer を管理するための[コントローラー](https://kubernetes.io/docs/concepts/architecture/controller/)です。

このコントローラーは次のリソースをプロビジョニングできます：

- Kubernetes `Ingress`を作成すると、AWS Application Load Balancer がプロビジョニングされます。
- `LoadBalancer`タイプの Kubernetes `Service`を作成すると、AWS Network Load Balancer がプロビジョニングされます。

Application Load Balancer は OSI モデルの`L7`で動作し、イングレスルールを使用して Kubernetes サービスを公開し、外部向けのトラフィックをサポートします。Network Load Balancer は OSI モデルの`L4`で動作し、Kubernetes の`Service`を活用してポッドのセットをアプリケーションネットワークサービスとして公開できます。

このコントローラーを使用すると、Kubernetes クラスター内の複数のアプリケーション間で Application Load Balancer を共有することで、運用を簡素化しコストを削減できます。

AWS Load Balancer Controller のインストール手順は次のセクションで説明され、AWS でロードバランサーリソースの作成を開始できるようになります。

:::info
AWS Load Balancer Controller は以前 AWS ALB Ingress Controller と呼ばれていました。
:::
