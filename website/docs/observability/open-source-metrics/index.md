---
title: "EKS open source observability"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Use open source observability solutions like Prometheus and Grafana with Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss-metrics
```

This will make the following changes to your lab environment:

- Install the EKS Pod Identity Agent add-on (a prerequisite for granting the CloudWatch agent permissions via EKS Pod Identity)
- Provision an Amazon Managed Service for Prometheus workspace
- Install Grafana in the cluster with the workspace configured as a data source

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss-metrics/.workshop/terraform).

:::

In this lab, we'll collect the metrics from the application using the [Amazon CloudWatch Observability EKS add-on](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html), store the metrics in Amazon Managed Service for Prometheus and visualize them using Grafana.

The CloudWatch Observability add-on deploys the CloudWatch agent, which is built on open source: it [runs an embedded OpenTelemetry collector](https://github.com/aws/amazon-cloudwatch-agent) and ships logs with [Fluent Bit](https://fluentbit.io/). Part of the Cloud Native Computing Foundation, [OpenTelemetry](https://opentelemetry.io/) provides open source APIs, libraries, and agents to collect distributed traces and metrics for application monitoring. Because the collector bundles the Prometheus receiver and the Prometheus Remote Write exporter, we can use the add-on to scrape Prometheus metrics from the cluster and remote-write them to Amazon Managed Service for Prometheus, with no separate collector to deploy or maintain.

Amazon Managed Service for Prometheus is a Prometheus-compatible monitoring service based on the Cloud Native Computing Foundation (CNCF) Prometheus project. It removes the work of running and scaling your own Prometheus, whether you are monitoring Amazon Elastic Kubernetes Service, Amazon Elastic Container Service, or self-managed Kubernetes clusters.

:::info
If you are using the CDK Observability Accelerator then check out the collection of Open Source Observability Patterns covering a wide range of use cases including [ADOT collector](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/existing-eks-observability-accelerators/existing-eks-adotmetrics-collection-observability/), [GPU Monitoring with Nvidia DCGM](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/single-new-eks-observability-accelerators/single-new-eks-gpu-opensource-observability/) and many more.
:::
