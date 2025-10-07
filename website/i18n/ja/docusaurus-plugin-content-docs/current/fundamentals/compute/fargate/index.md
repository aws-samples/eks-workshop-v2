---
title: Fargate
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "AWS Fargate、コンテナ向けサーバーレスコンピューティングエンジンをAmazon Elastic Kubernetes Serviceで活用します。"
kiteTranslationSourceHash: 4859572d78ac6f16145958d8ed2bfa3a
---

::required-time

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=400 wait=30
$ prepare-environment fundamentals/fargate
```

これにより、ラボ環境に次の変更が適用されます：

- Fargateで使用するIAMロールを作成

この変更を適用するTerraformコードは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/fargate/.workshop/terraform)で確認できます。

:::

前のモジュールでは、EKSクラスターでPodを実行するためのEC2コンピューティングインスタンスのプロビジョニング方法と、マネージドノードグループが運用の負担を軽減する方法を見てきました。しかし、このモデルでは、基盤となるインフラストラクチャの可用性、容量、およびメンテナンスについてはまだ責任があります。

[AWS Fargate](https://aws.amazon.com/fargate/)は、コンテナ用のオンデマンドで適切なサイズのコンピューティング容量を提供するテクノロジーです。AWS Fargateを使用すると、コンテナを実行するために仮想マシンのグループをプロビジョニング、設定、またはスケーリングする必要がありません。また、サーバータイプを選択したり、ノードグループをいつスケーリングするかを決定したり、クラスターのパッキングを最適化したりする必要もありません。Fargateプロファイルを使用して、どのPodがFargateで起動するか、およびそれらがどのように実行されるかを制御できます。FargateプロファイルはAmazon EKSクラスターの一部として定義されます。

![Fargate Architecture](./assets/fargate.webp)

Amazon EKSは、Kubernetesが提供する上流の拡張可能なモデルを使用してAWSによって構築されたコントローラーを使用して、KubernetesとAWS Fargateを統合します。これらのコントローラーはAmazon EKSマネージドKubernetesコントロールプレーンの一部として実行され、ネイティブKubernetes PodをFargateにスケジュールする責任を持ちます。Fargateコントローラーには、デフォルトのKubernetesスケジューラーと一緒に実行される新しいスケジューラーに加えて、いくつかの変更および検証アドミッションコントローラーが含まれます。FargateでPodを実行するための基準を満たすPodを起動すると、クラスター内で実行されているFargateコントローラーがPodを認識し、更新し、Fargateにスケジュールします。

Fargateの利点には以下が含まれます：

- AWS Fargateを使用すると、アプリケーションに集中できます。アプリケーションのコンテンツ、ネットワーク、ストレージ、スケーリング要件を定義します。プロビジョニング、パッチ適用、クラスター容量管理、またはインフラストラクチャ管理は必要ありません。
- AWS Fargateは、マイクロサービスアーキテクチャアプリケーション、バッチ処理、機械学習アプリケーション、オンプレミスアプリケーションのクラウドへの移行など、一般的なコンテナのユースケースをすべてサポートしています。
- 分離モデルとセキュリティのためにAWS Fargateを選択してください。また、EC2インスタンスをプロビジョニングまたは管理せずにコンテナを起動する場合は、Fargateを選択してください。EC2インスタンスをより詳細に制御したり、より広範なカスタマイズオプションが必要な場合は、FargateなしでECSまたはEKSを使用してください。

