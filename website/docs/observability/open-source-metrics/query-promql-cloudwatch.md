---
title: "Query with PromQL in CloudWatch"
sidebar_position: 45
---

In this section we'll explore how to query the metrics collected by the OpenTelemetry-based CloudWatch agent using PromQL (Prometheus Query Language) directly in Amazon CloudWatch Query Studio. This provides a unified interface to explore Container Insights infrastructure metrics and application metrics — all without needing a separate Prometheus server.

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#query-studio" service="cloudwatch" label="Open CloudWatch Query Studio"/>

To get started, navigate to **Query Studio** in the CloudWatch console left navigation menu under the Metrics section, and select **PromQL** as the query language.

## Verifying metrics collection

First, let's confirm the CloudWatch agent is running and collecting metrics from the cluster:

```bash
$ kubectl get pods -n amazon-cloudwatch
NAME                                                              READY   STATUS    RESTARTS   AGE
amazon-cloudwatch-observability-controller-manager-7bf79bbjc8w5   1/1     Running   0          19m
cloudwatch-agent-cluster-scraper-7578f8fccb-8cxjm                 1/1     Running   0          18m
cloudwatch-agent-pfsvk                                            1/1     Running   0          18m
cloudwatch-agent-wm6lp                                            1/1     Running   0          18m
cloudwatch-agent-zqvz8                                            1/1     Running   0          18m
kube-state-metrics-754d95978-7s5cp                                1/1     Running   0          19m
node-exporter-78rgq                                               1/1     Running   0          19m
node-exporter-nlkc9                                               1/1     Running   0          19m
node-exporter-ztqcg                                               1/1     Running   0          19m
```

You should see `cloudwatch-agent` pods running on each node (as a DaemonSet), a cluster scraper, kube-state-metrics, and node-exporter pods. These components work together to collect infrastructure and application metrics via OpenTelemetry and send them to CloudWatch.

Metrics start appearing in Query Studio within 5 minutes of the pods being ready and you can query them using PromQL or SQL syntax based queries. Go ahead and try running these below sample queries. 

![CW Query Studio PromQL results](/docs/observability/open-source-metrics/cw-promql-query.webp)

## Cluster-level metrics

These queries provide a high-level view of overall cluster health and resource utilization.

**Total cluster CPU usage** — aggregate CPU consumption across all containers:

```text
sum(rate(container_cpu_usage_seconds_total[5m]))
```

**Average CPU usage per namespace** — shows the mean CPU consumption per namespace, useful for baselining:

```text
avg by(k8s_namespace_name) (rate(container_cpu_usage_seconds_total[5m]))
```

**Maximum memory usage by namespace** — identifies the peak memory consumer in each namespace:

```text
max by(k8s_namespace_name) (container_memory_working_set_bytes)
```

**CPU usage by namespace** — total CPU broken down by namespace:

```text
sum by(k8s_namespace_name) (rate(container_cpu_usage_seconds_total[5m]))
```

## Node metrics

These queries focus on individual node health and capacity, useful for identifying hotspots or underutilized nodes.

**Node CPU utilization percentage** — shows how much of each node's CPU capacity is being used:

```text
sum by(kubernetes_io_hostname) (rate(node_cpu_seconds_total{mode!="idle"}[5m])) / sum by(kubernetes_io_hostname) (rate(node_cpu_seconds_total[5m])) * 100
```

**Minimum available memory per node** — find the node closest to running out of memory:

```text
min by(kubernetes_io_hostname) (node_memory_MemAvailable_bytes)
```

**Node filesystem usage percentage** — disk utilization as a percentage per node:

```text
(sum by(kubernetes_io_hostname) (node_filesystem_size_bytes - node_filesystem_avail_bytes)) / sum by(kubernetes_io_hostname) (node_filesystem_size_bytes) * 100
```

**Node count by instance type** — useful for understanding your cluster's compute composition:

```text
count by(node_kubernetes_io_instance_type) (kube_node_info)
```

## Pod metrics

Pod-level queries help you understand workload distribution and scheduling patterns.

**Pod count by namespace** — gives a quick view of workload density per namespace:

```text
sum by(k8s_namespace_name) (kube_pod_info)
```

**Pod count by availability zone** — shows how your pods are distributed across AZs:

```text
count by(topology_kubernetes_io_zone) (kube_pod_info)
```

**Pod count by node** — identifies if pods are evenly spread or concentrated on specific nodes:

```text
count by(kubernetes_io_hostname) (kube_pod_info)
```

**Running pods per namespace** — useful for verifying expected replica counts:

```text
count by(k8s_namespace_name) (container_cpu_usage_seconds_total)
```

## Container metrics

Container-level metrics give you insight in to individual workload resource consumption.

**Top 5 pods by CPU usage** — uses topk to surface the heaviest consumers:

```text
topk(5, sum by(k8s_namespace_name, k8s_pod_name) (rate(container_cpu_usage_seconds_total[5m])))
```

**Bottom 5 pods by memory** — find the lightest workloads using bottomk:

```text
bottomk(5, sum by(k8s_namespace_name, k8s_pod_name) (container_memory_working_set_bytes))
```

**CPU usage rate per pod** — drill down to individual pod CPU consumption:

```text
sum by(k8s_pod_name) (rate(container_cpu_usage_seconds_total[5m]))
```

**Average memory per pod** — useful for right-sizing resource requests:

```text
avg by(k8s_pod_name) (container_memory_working_set_bytes)
```

## Network metrics

Network metrics help identify traffic patterns, bottlenecks, and imbalanced load across nodes.

**Network receive rate by node** — identifies which nodes are handling the most inbound traffic:

```text
sum by(kubernetes_io_hostname) (rate(node_network_receive_bytes_total[5m]))
```

**Network transmit rate by node** — outbound traffic per node:

```text
sum by(kubernetes_io_hostname) (rate(node_network_transmit_bytes_total[5m]))
```

**Total cluster network throughput** — combined inbound and outbound across all nodes:

```text
sum(rate(node_network_receive_bytes_total[5m])) + sum(rate(node_network_transmit_bytes_total[5m]))
```

**Maximum network error rate across nodes** — surfaces the node with the worst network health:

```text
max by(kubernetes_io_hostname) (rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m]))
```

## Application and service metrics

These queries cover HTTP-level metrics exposed by services running in the cluster.

**HTTP request rate by namespace** — shows which services are receiving the most traffic:

```text
sum by(k8s_namespace_name) (rate(http_requests_total[5m]))
```

**HTTP request rate across the entire cluster** — overall request throughput:

```text
sum(rate(http_requests_total[5m]))
```

:::info
Custom application metrics (such as business KPIs or framework-specific metrics like JVM heap or Node.js internals) require additional collector configuration to be sent to CloudWatch. The metrics in this section represent what is available out-of-the-box with the CloudWatch Observability addon's OTel Container Insights configuration.
:::

## PromQL patterns reference

Here is a summary of the PromQL patterns used in the queries above, which you can adapt for your own metrics:

| Pattern | Description | Example |
|---------|-------------|---------|
| `sum by(label) (metric)` | Aggregate and group by a label | `sum by(k8s_namespace_name) (kube_pod_info)` |
| `avg by(label) (metric)` | Average value grouped by a label | `avg by(k8s_namespace_name) (rate(container_cpu_usage_seconds_total[5m]))` |
| `max by(label) (metric)` | Maximum value grouped by a label | `max by(k8s_namespace_name) (container_memory_working_set_bytes)` |
| `min by(label) (metric)` | Minimum value grouped by a label | `min by(kubernetes_io_hostname) (node_memory_MemAvailable_bytes)` |
| `topk(n, metric)` | Top N series by value | `topk(5, sum by(k8s_pod_name) (rate(container_cpu_usage_seconds_total[5m])))` |
| `bottomk(n, metric)` | Bottom N series by value | `bottomk(5, sum by(k8s_pod_name) (container_memory_working_set_bytes))` |
| `rate(metric[duration])` | Per-second rate of change over a time window | `rate(container_cpu_usage_seconds_total[5m])` |
| `count by(label) (metric)` | Count series grouped by a label | `count by(topology_kubernetes_io_zone) (kube_pod_info)` |
| `{label="value"}` | Filter by label value | `container_cpu_usage_seconds_total{k8s_namespace_name="orders"}` |
| `metric_a / metric_b * 100` | Compute a ratio as percentage | Node CPU utilization example above |
| `metric_a + metric_b` | Combine two metrics | Total network throughput example above |

## Pinning results to a dashboard

After running any query in Query Studio, you can save the visualization to a CloudWatch dashboard:

1. Run a PromQL query and review the results
2. Click **Actions → Add to dashboard**
3. Select an existing dashboard or create a new one
4. The visualization is saved and will auto-refresh on the dashboard

This is useful for building operational dashboards that combine infrastructure metrics from multiple namespaces or availability zones.

## Creating an alarm from PromQL

You can create CloudWatch alarms directly from any PromQL query result:

1. Run a query in Query Studio (for example, the node CPU utilization query above)
2. Click the **bell icon** next to the query result
3. The alarm creation wizard opens with your PromQL expression pre-filled
4. Configure the threshold (e.g., greater than 80% CPU utilization)
5. Set notification actions (SNS topic)
6. Name the alarm and create it

:::info
PromQL-based alarms evaluate on the same schedule as standard CloudWatch alarms. The minimum evaluation period is 1 minute.
:::

## Query Studio features

The Query Studio interface provides several capabilities to help explore metrics efficiently:

- **Visual query builder** — Select metrics from a dropdown, add label filters, choose aggregation functions (sum, avg, rate), and group by labels without writing raw PromQL. Click "Switch to editor" to see the generated expression.
- **Multiple queries** — Click **+ Add query** to run additional queries side by side. Each query runs independently and results are displayed together for comparison.
- **Configure visualization** — Click the **Configure** button on any result to change the chart type (line chart, stacked area, bar chart) and adjust display options.
