---
title: "Kubecostによるコスト可視化"
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "KubecostによりAmazon Elastic Kubernetes Serviceを使用するチームのコスト可視性とインサイトを獲得します。"
kiteTranslationSourceHash: e20f9e5f9b5d9256c23c154ba9c78128
---

::required-time

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment observability/kubecost
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon EKSクラスターにAWS Load Balancerコントローラーをインストールします
- EBS CSIドライバーのEKSマネージドアドオンをインストールします

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/kubecost/.workshop/terraform)から確認できます。

:::

Kubecostは、Kubernetesを使用するチームにリアルタイムのコスト可視性とインサイトを提供し、クラウドコストを継続的に削減するのに役立ちます。

AWS Cost and Usage Reportsを使用してKubernetesコントロールプレーンとEC2コストを追跡できますが、より深いインサイトが必要な場合もあります。Kubecostを使用すると、名前空間、クラスター、ポッド、または組織的な概念（チームやアプリケーション別など）ごとにKubernetesリソースを正確に追跡できます。これは、マルチテナントクラスター環境を実行しており、クラスター内のテナント別にコストを内訳する必要がある場合にも役立ちます。例えば、Kubecostを使用すると、特定のポッドグループが使用するリソースを判断できますが、通常、顧客は特定の期間のコンピューティングリソースの使用量を手動で集計してコストを計算する必要がありました。さらに、コンテナは短命であり、さまざまなレベルでスケールするため、リソースの使用量は時間とともに変動し、この方程式にさらに複雑さを加えます。

これはまさにKubecostが取り組んでいる課題です。2019年に設立されたKubecostは、Kubernetes環境での支出とリソース効率の可視性を顧客に提供するために立ち上げられ、今日では何千ものチームがこの課題に対処するのを支援しています。KubecostはOpenCostをベースにしており、最近Cloud Native Computing Foundation（CNCF）のSandboxプロジェクトとして受け入れられ、AWSによって積極的にサポートされています。

この章では、Kubecostを使用して名前空間レベル、デプロイメントレベル、ポッドレベルでさまざまなコンポーネントのコスト割り当てを測定する方法を見ていきます。また、デプロイメントが過剰にプロビジョニングされているか、または過少にプロビジョニングされているか、システムの健全性などを確認するためのリソース効率も確認します。

:::tip
このモジュールを完了した後、Kubecostと[Amazon Managed Service for Prometheus](https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html)を使用して、単一のEKSクラスターを超えてコストの可視性を拡張する方法について[マルチクラスターコストモニタリング](https://aws.amazon.com/blogs/containers/multi-cluster-cost-monitoring-using-kubecost-with-amazon-eks-and-amazon-managed-service-for-prometheus/)をチェックしてください。[Amazon Cognitoを使用してKubecostダッシュボードへのアクセスを保護する方法](https://aws.amazon.com/blogs/containers/securing-kubecost-access-with-amazon-cognito/)についても学びましょう。

:::

:::info
CDK Observability Acceleratorを使用している場合は、[Kubecost Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/kubecost/)をチェックしてください。このアドオンは、EKSクラスター用のKubecostとAMPのセットアップ​​プロセスを大幅に簡素化します。
:::
