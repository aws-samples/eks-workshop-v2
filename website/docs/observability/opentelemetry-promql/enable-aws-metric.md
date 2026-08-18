---
title: "Enable AWS vended metric enrichment"
sidebar_position: 10
---

To ingest and query OpenTelemetry metrics in Amazon CloudWatch, there are two account-level settings to enable, which can be done through the AWS console, AWS CLI, or AWS SDK. The first setting enables resource tag propagation  from your AWS resources to your telemetry data, the same tags that are visible in AWS Resource Explorer. The second enables OpenTelemetry metrics ingestion  for CloudWatch.

Let's enable these two settings. You can use either the AWS Console or the AWS CLI.


**Architecture**

Amazon CloudWatch exposes a regional OTLP endpoint that OpenTelemetry-compatible collectors and SDKs can send metrics to directly. Metrics are stored in a high-cardinality metrics store that retains OpenTelemetry metric types including counters, histograms, gauges, and up-down counters without conversion. When enrichment is enabled, CloudWatch automatically tags vended metrics with AWS resource context such as account ID, region, cluster ARN, and resource tags from AWS Resource Explorer. This enrichment requires no manual instrumentation, enabling you to query and filter across AWS accounts, regions, and resource tags using PromQL in Amazon CloudWatch Query Studio or Amazon Managed Grafana.



**Option A: AWS Console**

1. Open the Amazon CloudWatch console <ConsoleButton url="https://console.aws.amazon.com/eks/home#/clusters/eks-workshop?selectedTab=cluster-logging-tab" service="eks" label="Open EKS console"/>
2. In the left navigation, choose Settings
3. In the Resource tags on telemetry section, toggle Enable resource tags for telemetry to On
4. In the OTel metric ingestion section, toggle Enable OTel metric ingestion to On

![Cloudwatch Settings](/docs/observability/opentelemetry-promql/enabled_otel_resource_tags.webp)


**Option B: AWS CLI**

Enable resource tags for telemetry data

```bash hook=cluster-logging
$ aws observabilityadmin start-telemetry-enrichment
```

Enable OpenTelemetry metrics ingestion for Amazon CloudWatch


```bash hook=cluster-logging
$ aws cloudwatch start-otel-enrichment
```

