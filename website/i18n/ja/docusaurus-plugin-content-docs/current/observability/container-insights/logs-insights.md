---
title: "CloudWatch Logs Insightsの使用"
sidebar_position: 30
weight: 5
tmdTranslationSourceHash: '8340e8f3f96af28c2b8fe65a1d697038'
---

Container Insightsは、CloudWatch Logsに保存されている[Embedded Metric Format](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html)を使用したパフォーマンスログイベントによってメトリクスを収集します。CloudWatchはログから複数のメトリクスを自動的に生成し、CloudWatchコンソールで確認することができます。また、CloudWatch Logs Insightsクエリを使用して、収集されたパフォーマンスデータのより深い分析を行うこともできます。

まず、CloudWatch Log Insightsコンソールを開きます：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#logsV2:logs-insights" service="cloudwatch" label="CloudWatchコンソールを開く"/>

画面上部にクエリエディタがあります。CloudWatch Logs Insightsを最初に開くと、このボックスには直近の20件のログイベントを返すデフォルトクエリが含まれています。

ロググループを選択してクエリを実行すると、CloudWatch Logs Insightsはロググループ内のデータのフィールドを自動的に検出し、右ペインの**検出されたフィールド**に表示します。また、このロググループ内のログイベントの時系列の棒グラフも表示されます。この棒グラフは、クエリとタイムレンジに一致するロググループ内のイベントの分布を示しており、テーブルに表示されるイベントだけではありません。`/performance`で終わるEKSクラスターのロググループを選択してください。

クエリエディタで、デフォルトクエリを次のクエリに置き換えて、**クエリの実行**を選択します。

```text
STATS avg(node_cpu_utilization) as avg_node_cpu_utilization by NodeName
| SORT avg_node_cpu_utilization DESC
```

![Query1](/docs/observability/container-insights/query1.webp)

このクエリは、平均ノードCPU使用率でソートされたノードのリストを表示します。

もう一つの例を試すには、そのクエリを別のクエリに置き換えて、**クエリの実行**を選択します。

```text
STATS avg(number_of_container_restarts) as avg_number_of_container_restarts by PodName
| SORT avg_number_of_container_restarts DESC
```

![Query2](/docs/observability/container-insights/query2.webp)

このクエリは、コンテナの再起動の平均回数でソートされたPodのリストを表示します。

別のクエリを試したい場合は、画面右側のフィールドリストを使用できます。クエリ構文の詳細については、[CloudWatch Logs Insightsクエリ構文](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)を参照してください。

