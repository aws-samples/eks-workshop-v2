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

In this lab, we will explore the use of [OpenSearch](https://opensearch.org/about.html) for observability. OpenSearch is a community-driven, open-source search and analytics suite used to ingest, search, visualize and analyze data. OpenSearch consists of a data store and search engine (OpenSearch), a visualization and user interface (OpenSearch Dashboards), and a server-side data collector (Data Prepper). We will be using [Amazon OpenSearch Service](https://aws.amazon.com/opensearch-service/), which is a managed service that makes it easy for you to perform interactive log analytics, real-time application monitoring, search, and more.

Kubernetes events, control plane logs and pod logs are exported from Amazon EKS to Amazon OpenSearch Service to demonstrate how the two Amazon services can be used together to improve observability.
