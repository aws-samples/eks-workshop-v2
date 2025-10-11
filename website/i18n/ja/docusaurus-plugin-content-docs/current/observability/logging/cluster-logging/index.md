---
title: "コントロールプレーンログ"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "監査と診断のために Amazon Elastic Kubernetes Service コントロールプレーンログをキャプチャし分析します。"
kiteTranslationSourceHash: 8fb3e741f3feb886f47f3087641060bf
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment observability/logging/cluster
```

:::

Amazon EKSコントロールプレーンロギングは、Amazon EKSコントロールプレーンから直接監査および診断ログをアカウント内のCloudWatch Logsに提供します。これらのログにより、クラスターの安全な実行が容易になります。必要なログタイプを正確に選択でき、ログはCloudWatch内の各Amazon EKSクラスター用のグループにログストリームとして送信されます。

AWS Management Console、AWS CLI（バージョン1.16.139以上）、またはAmazon EKS APIを使用して、クラスターごとに各ログタイプを有効または無効にすることができます。

Amazon EKSコントロールプレーンロギングを使用すると、実行する各クラスターに対して標準のAmazon EKS料金が課金され、クラスターからCloudWatch Logsに送信されるすべてのログに対して標準のCloudWatch Logsデータ取り込みおよびストレージコストが発生します。

以下のクラスターコントロールプレーンログタイプが利用可能です。各ログタイプはKubernetesコントロールプレーンのコンポーネントに対応しています。これらのコンポーネントの詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/overview/components/)のKubernetesコンポーネントを参照してください。

- **Kubernetes APIサーバーコンポーネントログ（api）** – クラスターのAPIサーバーは、Kubernetes APIを公開するコントロールプレーンコンポーネントです。
- **監査（audit）** – Kubernetes監査ログは、クラスターに影響を与えた個々のユーザー、管理者、またはシステムコンポーネントの記録を提供します。
- **認証機能（authenticator）** – 認証機能ログはAmazon EKSに固有のものです。これらのログは、Amazon EKSがIAM認証情報を使用してKubernetes [ロールベースアクセス制御](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)（RBAC）認証に使用するコントロールプレーンコンポーネントを表します。
- **コントローラーマネージャー（controllerManager）** – コントローラーマネージャーはKubernetesに付属するコアコントロールループを管理します。
- **スケジューラー（scheduler）** – スケジューラーコンポーネントは、クラスター内のポッドがいつどこで実行されるかを管理します。

