---
title: "Observability"
sidebar_position: 10
weight: 10
---
Observability is a foundational element of a well-architected EKS environment. AWS provides native (Cloudwatch) and open source managed (Amazon Managed Service for Prometheus, Amazon Managed Grafana and AWS Distro for OpenTelemetry) solutions for monitoring, logging, alarming, and dashboarding of EKS environments.

In this Observability module we will cover how you can use AWS observability solutions integrated with EKS to provide visibility into:

    - Kubernetes Resources in the EKS Console View
    - Control Plane and Pod Logs utilizing Fluentbit
    - Monitoring Metrics with Cloudwatch Container Insights
    - Monitoring EKS Metrics with AMP and ADOT.

:::info
To Dive Deeper into AWS Observability features take a look at the [One Observability Workshop](https://observability.workshop.aws)
:::