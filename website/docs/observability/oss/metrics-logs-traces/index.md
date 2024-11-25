---
title: "Metrics, logs and traces"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Leverage open source observability solutions like Prometheus, Loki, Tempo, OpenTelemetry and Grafana with Amazon Elastic Kubernetes Service."
# cSpell:ignore Zipkin
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss/metrics-logs-traces
```

This will make the following changes to your lab environment:

- Install the OpenTelemetry operator, Grafana operator, Loki and Tempo
- Create an IAM role for the ADOT collector to access Amazon Managed Prometheus
- Provision an Amazon Managed Service for Prometheus (AMP) workspace

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss/metrics-logs-traces/.workshop/terraform).

:::

AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the [OpenTelemetry project](https://opentelemetry.io/) . Part of the Cloud Native Computing Foundation, OpenTelemetry provides open source APIs, libraries, and agents to collect distributed traces and metrics for application monitoring. With AWS Distro for OpenTelemetry, you can instrument your applications just once to send correlated metrics and traces to multiple AWS and Partner monitoring solutions. Use auto-instrumentation agents to collect traces without changing your code. AWS Distro for OpenTelemetry also collects metadata from your AWS resources and managed services, so you can correlate application performance data with underlying infrastructure data, reducing the mean time to problem resolution. Use AWS Distro for OpenTelemetry to instrument your applications running on Amazon Elastic Compute Cloud (EC2), Amazon Elastic Container Service (ECS), and Amazon Elastic Kubernetes Service (EKS) on EC2, AWS Fargate, and AWS Lambda, as well as on-premises.

Amazon Managed Service for Prometheus is a monitoring service for metrics compatible with the open source Prometheus project, making it easier for you to securely monitor container environments. Amazon Managed Service for Prometheus is a solution for monitoring containers based on the popular Cloud Native Computing Foundation (CNCF) Prometheus project. Amazon Managed Service for Prometheus reduces the heavy lifting required to get started with monitoring applications across Amazon Elastic Kubernetes Service and Amazon Elastic Container Service, as well as self-managed Kubernetes clusters.

Loki is an open source log aggregation system developed by Grafana Labs and publicly available since 2018. It is designed to efficiently collect, aggregate, and visualize logs from various sources. Unlike traditional log management systems, Loki does not index the content of the logs. Instead, it uses a set of labels to index metadata associated with each log stream, making it highly scalable and cost-effective.

Tempo is an open source, high-scale distributed tracing backend developed by Grafana Labs and publicly available since 2020. It is designed to be cost-efficient and easy to use, requiring only object storage to operate. Tempo integrates seamlessly with other open source observability tools like Prometheus and Loki, as well as open source tracing protocols such as Jaeger, Zipkin, and OpenTelemetry.
