---
title: "Cluster metrics"
sidebar_position: 10
---

We're going to explore how to enable CloudWatch Container Insights metrics for an EKS cluster with the ADOT Collector. The first thing we'll need to do is create a collector in our cluster to gather metrics related to various aspects of the cluster such as nodes, pods and containers.

You can view the full collector manifest below, then we'll break it down.

<details>
  <summary>Expand for full collector manifest</summary>

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml"}

</details>

We can review this in several parts to make better sense of it.

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.image" zoomAfter="1"}

The OpenTelemetry collector can run in several different modes depending on the telemetry it is collecting. In this case we'll run it as a DaemonSet so that a pod runs on each node in the EKS cluster. This allows us to collect telemetry from the node and container runtime.

Next we can start to break down the collector configuration itself.

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.receivers.awscontainerinsightreceiver" zoomBefore="2"}

First we'll configure the [AWS Container Insights Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/9da7fea0097b991b771e0999bc4cd930edb221e2/receiver/awscontainerinsightreceiver/README.md) to collect metrics from the node.

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.processors"}

Next we'll use a batch processor to reduce the number of API calls to CloudWatch by flushing metrics buffered over at most 60 seconds.

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.exporters.awsemf/performance.namespace" zoomBefore="2" zoomAfter="1"}

And now we'll use the [AWS CloudWatch EMF Exporter for OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md) to convert the OpenTelemetry metrics to [AWS CloudWatch Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html) and then send them directly to CloudWatch Logs using the [PutLogEvents](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html) API. The log entries will be sent to the CloudWatch Logs log group shown and use the metrics will appear in the `ContainerInsights` namespace. This rest of this section is too long to view in full but see the complete manifest above.

::yaml{file="manifests/modules/observability/container-insights/adot/opentelemetrycollector.yaml" zoomPath="spec.config.service.pipelines"}

Finally we need to use an OpenTelemetry pipeline to combine our receiver, processor and exporter.

We'll use the managed IAM policy `CloudWatchAgentServerPolicy` to provide the collector with the IAM permissions it needs via IAM Roles for Service Accounts to send the metrics to CloudWatch:

```bash
$ aws iam list-attached-role-policies \
  --role-name eks-workshop-adot-collector-ci | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "CloudWatchAgentServerPolicy",
      "PolicyArn": "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  ]
}
```

This IAM role will be added to the ServiceAccount for the collector:

```file
manifests/modules/observability/container-insights/adot/serviceaccount.yaml
```

Create the resources we've explored above:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/container-insights/adot \
  | envsubst | kubectl apply -f- && sleep 5
$ kubectl rollout status -n other daemonset/adot-container-ci-collector --timeout=120s
```

We can confirm that our collector is running by inspecting the Pods created by the DaemonSet:

```bash hook=metrics
$ kubectl get pod -n other -l app.kubernetes.io/name=adot-container-ci-collector
NAME                               READY   STATUS    RESTARTS   AGE
adot-container-ci-collector-5lp5g  1/1     Running   0          15s
adot-container-ci-collector-ctvgs  1/1     Running   0          15s
adot-container-ci-collector-w4vqs  1/1     Running   0          15s
```

This shows the collector is running and collecting metrics from the cluster. To view metrics first open the CloudWatch console and navigate to Container Insights:

:::tip
Please note that:

1. It may take a few minutes for data to start appearing in CloudWatch
2. It is expected that some metrics are missing since they are provided by the [CloudWatch agent with enhanced observability](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-agent.html)

:::

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#container-insights:performance/EKS:Cluster?~(query~(controls~(CW*3a*3aEKS.cluster~(~'eks-workshop)))~context~())" service="cloudwatch" label="Open CloudWatch console"/>

![ContainerInsightsConsole](./assets/container-insights-metrics-console.webp)

You can take some time to explore around the console to see the various ways that metrics are presented such as by cluster, namespace or pod.
