---
title: "Observability"
sidebar_position: 10
weight: 10
---

Observability is a foundational element of a well-architected EKS environment. AWS provides native (CloudWatch) and open source managed (Amazon Managed Service for Prometheus, Amazon Managed Grafana and AWS Distro for OpenTelemetry) solutions for monitoring, logging, alarming, and dashboarding of EKS environments.

In this chapter,  we'll cover how you can use AWS observability solutions integrated with EKS to provide visibility into:

* Kubernetes Resources in the EKS console view
* Control Plane and Pod Logs utilizing Fluentbit
* Monitoring Metrics with CloudWatch Container Insights
* Monitoring EKS Metrics with AMP and ADOT.

:::info
To dive deeper into AWS Observability features take a look at the [One Observability Workshop](https://observability.workshop.aws)
:::
