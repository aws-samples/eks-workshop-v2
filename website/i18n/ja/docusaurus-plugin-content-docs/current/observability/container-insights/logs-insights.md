---
title: "CloudWatch Log Analyticsの使用"
sidebar_position: 30
weight: 5
tmdTranslationSourceHash: '9dbbd6b10021d53a08a5254966093d52'
---

Container Insightsは、CloudWatch Logsに保存されている[Embedded Metric Format](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html)を使用したパフォーマンスログイベントによってメトリクスを収集します。CloudWatchはログから複数のメトリクスを自動的に生成し、CloudWatchコンソールで確認することができます。また、**Log Analytics**でクエリを実行して、収集されたパフォーマンスデータのより深い分析を行うこともできます。

まず、CloudWatch Log Analyticsコンソールを開きます：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#logsV2:logs-insights" service="cloudwatch" label="CloudWatchコンソールを開く"/>

画面上部にクエリエディタがあります。Log Analyticsを最初に開くと、このボックスには直近の20件のログイベントを返すデフォルトクエリが含まれています。

ロググループを選択してクエリを実行すると、Log Analyticsはロググループ内のデータのフィールドを自動的に検出し、右ペインの**Discovered fields**に表示します。また、このロググループ内のログイベントの時系列の棒グラフも表示されます。この棒グラフは、クエリとタイムレンジに一致するロググループ内のイベントの分布を示しており、テーブルに表示されるイベントだけではありません。`/performance`で終わるEKSクラスターのロググループを選択してください。

クエリエディタで、デフォルトクエリを次のクエリに置き換えて、**Run query**を選択します。

:::tip
クエリを実行する前に、ロググループ `/aws/containerinsights/eks-workshop/performance` が選択されていることを確認してください。選択されていない場合、結果は返されません。
:::

```text
STATS avg(node_cpu_utilization) as avg_node_cpu_utilization by NodeName
| SORT avg_node_cpu_utilization DESC
```

![Query1](/docs/observability/container-insights/query1.webp)

このクエリは、平均ノードCPU使用率でソートされたノードのリストを表示します。

もう一つの例を試すには、そのクエリを別のクエリに置き換えて、**Run query**を選択します。

```text
STATS avg(pod_memory_utilization) as avg_pod_memory_utilization by PodName
| SORT avg_pod_memory_utilization DESC
```

![Query2](/docs/observability/container-insights/query2.webp)

このクエリは、平均メモリ使用率でソートされたPodのリストを表示し、クラスタ内で最もメモリを消費するワークロードを特定するのに役立ちます。

別のクエリを試したい場合は、画面右側のフィールドリストを使用できます。クエリ構文の詳細については、[CloudWatch Logs Insightsクエリ構文](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)を参照してください。

