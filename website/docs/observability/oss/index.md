---
title: "Observability with open source solutions"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Build observability capabilities for Amazon Elastic Kubernetes Service around open source solutions."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss
```

This will make the following changes to your lab environment:

- Install the OpenTelemetry operator, Grafana operator, Loki and Tempo
- Create an IAM role for the ADOT collector to access Amazon Managed Prometheus
- Provision an Amazon Managed Service for Prometheus (AMP) workspace

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss/.workshop/terraform).

:::

In the 1st part of this lab, we'll collect the metrics, logs, and traces from the application using [AWS Distro for OpenTelemetry](https://aws-otel.github.io/), store the metrics in [Amazon Managed Service for Prometheus](https://aws.amazon.com/prometheus), logs in [Loki](https://grafana.com/oss/loki), traces in [Tempo](https://grafana.com/oss/tempo) and visualize using [Amazon Managed Grafana](https://aws.amazon.com/grafana).

In the 2nd part of this lab, we'll take a look at how to use [Kubecost](https://www.kubecost.com) to collect and store the data in [Amazon Managed Service for Prometheus](https://aws.amazon.com/prometheus) and then walkthrough some of its features that provide the cost visibility and insights for the workloads running inside the EKS cluster.
