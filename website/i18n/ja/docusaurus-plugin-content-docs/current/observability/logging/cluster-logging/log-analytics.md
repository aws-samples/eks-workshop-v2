---
title: "CloudWatch Log Analytics"
sidebar_position: 40
tmdTranslationSourceHash: 'a102f6d68e9a9b2d8e9d51b09e027dc3'
---

CloudWatch Log Analytics を使用すると、CloudWatch Logs のログデータをインタラクティブに検索および分析できます。クエリを実行することで、運用上の問題により効率的かつ効果的に対応できます。問題が発生した場合、Log Analytics を使用して潜在的な原因を特定し、デプロイされた修正を検証できます。これには、いくつかのシンプルながら強力なコマンドを備えた専用のクエリ言語が含まれています。

:::info
**Log Analytics** は、Logs Insights クエリエディタ、Live Tail、および Contributor Insights を単一のインターフェースに統合した CloudWatch コンソールエクスペリエンスであり、現在はデフォルトになっています。以前に独立した **Logs Insights** ページを使用していた場合、クエリエディタとクエリ構文は同じで、現在は Log Analytics の下に表示されます。
:::

このラボ演習では、Log Analytics を使用して EKS Control Plane ログをクエリする例を見ていきます。まず、コンソールで Log Analytics に移動します：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#logsV2:logs-insights" service="cloudwatch" label="CloudWatch コンソールを開く"/>

次のような画面が表示されます：

![log analytics initial](/docs/observability/logging/cluster-logging/log-insights-initial.webp)

Log Analytics の一般的なユースケースは、Kubernetes API サーバーに大量のリクエストを行っている EKS クラスター内のコンポーネントを特定することです。これを行う方法の1つは、次のクエリです：

```blank
fields userAgent, requestURI, @timestamp, @message
| filter @logStream ~= "kube-apiserver-audit"
| stats count(userAgent) as count by userAgent
| sort count desc
```

このクエリは Kubernetes 監査ログをチェックし、`userAgent` でグループ化された API リクエストの数をカウントし、降順でソートします。Log Analytics コンソールで、EKS クラスターのロググループを選択します：

![log insights group](/docs/observability/logging/cluster-logging/log-insights-group.webp)

クエリをコンソールにコピーして **Run query** を押すと、結果が返されます：

![log insights query](/docs/observability/logging/cluster-logging/log-insights-query.webp)

この情報は、どのコンポーネントが API サーバーにリクエストを送信しているかを理解するために非常に貴重です。

:::info
CDK Observability Accelerator を使用している場合は、[CloudWatch Insights Add-on](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-cloudwatch-insights/) をチェックしてください。これは、EKS のコンテナ化されたアプリケーションとマイクロサービスからメトリクスとログを収集、集約、および要約します。
:::

