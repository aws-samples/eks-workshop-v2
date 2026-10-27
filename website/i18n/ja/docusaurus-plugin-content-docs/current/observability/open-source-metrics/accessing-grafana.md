---
title: "Grafanaへのアクセス"
sidebar_position: 30
tmdTranslationSourceHash: '54efc8a0f55939ccf57287bf63e04122'
---

GrafanaのインスタンスはあなたのEKSクラスターに事前にインストールされています。アクセスするには、まずURLを取得する必要があります：

```bash hook=check-grafana
$ kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
k8s-grafana-grafana-123497e39be-2107151316.us-west-2.elb.amazonaws.com
```

このURLをブラウザで開くと、ログイン画面が表示されます。

![Grafanaダッシュボード](/docs/observability/open-source-metrics/grafana-login.webp)

ユーザーの認証情報を取得するには、Grafana helmチャートによって作成されたシークレットをクエリします：

```bash
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d; printf "\n"
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d; printf "\n"
```

Grafanaコンソールにログインした後、データソースセクションを見てみましょう。Amazon Managed Service for Prometheusワークスペースがデータソースとして既に設定されているはずです。

![Amazon Managed Service for Prometheusデータソース](/docs/observability/open-source-metrics/datasource.webp)

:::info 本番環境向けのAmazon Managed Grafana
このラボでは、セットアップをシンプルにするためにクラスター内でセルフマネージド型Grafanaを実行しています。本番環境では、通常、AWSがGrafana Labsと連携して運用する完全マネージド型サービスである[Amazon Managed Grafana](https://aws.amazon.com/grafana/)を使用することをお勧めします：

- **運用作業なし** — AWSがGrafanaのプロビジョニング、パッチ適用、スケーリング、および高可用性を提供するため、サーバーやバージョンアップグレードを管理する必要がありません。
- **AWS経由のEnterpriseプラグイン** — Grafana Labsの個別のEnterpriseライセンスなしで、AWS経由で直接Grafana Enterpriseデータソースプラグインをワークスペースでアップグレードして使用できます。
- **AWSネイティブなセキュリティ** — ユーザーはAWS IAM Identity CenterまたはSAMLを通じてサインインし、AWS Identity and Access Managementによってアクセスが管理されます。
- **組み込みのAWSデータソース** — Amazon Managed Service for Prometheus、Amazon CloudWatchなどとのネイティブな統合。

Amazon Managed Grafanaワークスペースは、このラボで使用する同じAmazon Managed Service for Prometheusワークスペースをデータソースとしてクエリできます。
:::
