---
title: "EKS open source observability"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Leverage open source observability solutions like Prometheus and Grafana with Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss-metrics
```

This will make the following changes to your lab environment:

- Install the OpenTelemetry operator
- Create an IAM role for the ADOT collector to access Amazon Managed Prometheus

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss-metrics/.workshop/terraform).

:::

In this lab, we'll collect the metrics from the application using [AWS Distro for OpenTelemetry](https://aws-otel.github.io/), store the metrics in Amazon Managed Service for Prometheus and visualize using Amazon Managed Grafana.

AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the [OpenTelemetry project](https://opentelemetry.io/) . Part of the Cloud Native Computing Foundation, OpenTelemetry provides open source APIs, libraries, and agents to collect distributed traces and metrics for application monitoring. With AWS Distro for OpenTelemetry, you can instrument your applications just once to send correlated metrics and traces to multiple AWS and Partner monitoring solutions. Use auto-instrumentation agents to collect traces without changing your code. AWS Distro for OpenTelemetry also collects metadata from your AWS resources and managed services, so you can correlate application performance data with underlying infrastructure data, reducing the mean time to problem resolution. Use AWS Distro for OpenTelemetry to instrument your applications running on Amazon Elastic Compute Cloud (EC2), Amazon Elastic Container Service (ECS), and Amazon Elastic Kubernetes Service (EKS) on EC2, AWS Fargate, and AWS Lambda, as well as on-premises.

Amazon Managed Service for Prometheus is a monitoring service for metrics compatible with the open source Prometheus project, making it easier for you to securely monitor container environments. Amazon Managed Service for Prometheus is a solution for monitoring containers based on the popular Cloud Native Computing Foundation (CNCF) Prometheus project. Amazon Managed Service for Prometheus reduces the heavy lifting required to get started with monitoring applications across Amazon Elastic Kubernetes Service and Amazon Elastic Container Service, as well as self-managed Kubernetes clusters.

:::info
If you are using the CDK Observability Accelerator then check out the collection of Open Source Observability Patterns covering a wide range of use cases including [ADOT collector](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/existing-eks-observability-accelerators/existing-eks-adotmetrics-collection-observability/), [GPU Monitoring with Nvidia DCGM](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/single-new-eks-observability-accelerators/single-new-eks-gpu-opensource-observability/) and many more.
:::
