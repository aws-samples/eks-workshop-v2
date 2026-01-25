---
title: "Observability with OpenSearch"
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "Build observability capabilities for Amazon Elastic Kubernetes Service around OpenSearch."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=3600 wait=30
$ prepare-environment observability/opensearch
```

This will make the following changes to your lab environment:

- Cleanup resources from earlier EKS workshop modules
- Provision an Amazon OpenSearch Service domain (see **note** below)
- Setup Lambda function that is used to export EKS control plane logs from CloudWatch Logs to OpenSearch

**Note**: If you are participating in an AWS event, the OpenSearch domain has been pre-provisioned for you to save time. On the other hand, if you are following these instructions within your own account, the `prepare-environment` step above provisions an OpenSearch domain, which can take up to 30 minutes to complete.

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/.workshop/terraform).

:::

The proposed observability strategy for this module lies the utilization of [OpenSearch](https://opensearch.org/about.html), a powerful community-driven, and scalable open-source search and analytics engine, and the Observability Pyramid (Logs, Metrics, Traces) framework. This strategy provides a starting point for participants to think about how to approach observability in their organizations.

The strategy begins with a focus on centralized logging, where all logs from the various EKS components (including worker nodes, control plane and containers), and application metrics and traceability are ingested into an OpenSearch cluster **(metrics and traces will be added in a future release)**. This allows for comprehensive log aggregation and tracing, enabling participants to leverage OpenSearch's robust search and analytics capabilities to gain visibility into system-wide events and identify potential issues.

Underpinning the technical aspects of this strategy is a focus on cultivating an observability-driven culture. By involving cross-functional teams, including developers, site reliability engineers (SREs), and DevOps professionals, in the adoption and maintenance of the OpenSearch-based observability solution, the participants can foster a collaborative environment where data-driven problem-solving and continuous improvement become the norm.

Now let's talk a little bit about [OpenSearch](https://opensearch.org/about.html). OpenSearch consists of a data store and search engine (OpenSearch), a visualization and user interface (OpenSearch Dashboards), and a server-side data collector (Data Prepper). We will be using [Amazon OpenSearch Service](https://aws.amazon.com/opensearch-service/), which is a managed service that makes it easy for you to perform interactive log analytics, real-time application monitoring, search, and more.

Kubernetes events, control plane logs and pod logs are exported from Amazon EKS to Amazon OpenSearch Service to demonstrate how the two Amazon services can be used together to improve observability.

:::info
You can find more information related to the Observability Pyramid (Logs, Metrics, Traces) framework in the book ["Observability Engineering" by Charity Majors et al](https://www.amazon.com/Observability-Engineering-Achieving-Production-Excellence/dp/1492076449)
:::
