---
title: "Enable AWS vended metric enrichment"
sidebar_position: 10
---


To ingest and query OpenTelemetry metrics in Amazon CloudWatch, there are two account-level settings to enable, which can be done through the AWS console, AWS CLI, or AWS SDK. The first setting enables resource tag propagation  from your AWS resources to your telemetry data, the same tags that are visible in AWS Resource Explorer. The second enables OpenTelemetry metrics ingestion  for CloudWatch.

Let's enable these two settings. You can use either the AWS Console or the AWS CLI.

**Option A: AWS Console**

1. Open the Amazon CloudWatch console <ConsoleButton url="https://console.aws.amazon.com/eks/home#/clusters/eks-workshop?selectedTab=cluster-logging-tab" service="eks" label="Open EKS console"/>
2. In the left navigation, choose Settings
3. In the Resource tags on telemetry section, toggle Enable resource tags for telemetry to On
4. In the OTel metric ingestion section, toggle Enable OTel metric ingestion to On

![Cloudwatch Settings](/docs/observability/logging/cluster-logging/enabled_otel_resource_tags.webp)


**Option B: AWS CLI**

:::info

The start-otel-enrichment command requires AWS CLI v2.34+. CloudShell includes the latest CLI. If running locally, update your CLI by following the [AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) .
Enrichment applies only to metrics going forward and does not backfill historical telemetry data. Allow 5–10 minutes for enriched metrics to start appearing.them in CloudWatch.
:::


Enable resource tags for telemetry data

```bash hook=cluster-logging
$ aws observabilityadmin start-telemetry-enrichment
```

Enable OpenTelemetry metrics ingestion for Amazon CloudWatch


```bash hook=cluster-logging
$ aws cloudwatch start-otel-enrichment
```


:::info
If you are using the CDK Observability Accelerator then check out the [CDK Observability Builder](https://aws-quickstart.github.io/cdk-eks-blueprints/builders/observability-builder/#supported-methods) which supports enabling all control plane logging features for EKS clusters and storing them in CloudWatch.
:::
