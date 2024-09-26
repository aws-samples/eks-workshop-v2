---
title: "Deploy and Monitor GenAI Model on EKS"
sidebar_position: 10
sidebar_custom_props: { "beta": true }
description: "Deploy and Monitor GenAI Model on EKS"
---

:::danger
This module is not supported at AWS events or in AWS-vended accounts through Workshop Studio. This module is only supported for clusters created through the "[In your AWS account](/docs/introduction/setup/your-account)" steps.
:::

:::tip Before you start
Prepare your environment for this section:

```bash timeout=1800 wait=30
$ prepare-environment aiml/deploy-monitor-genai-model
```

Its takes around 25 mins to complete the initial preparation, this will make the following changes to your lab environment:

 - Creates EKS cluster 
 - Install EBS CSI Driver, AWS Load Balancer controller and Karpenter controller
 - Installs Amazon Managed Prometheus, Grafana and AWS managed collector
:::

This lab will cover we'll cover various aspects from provisioning GPU nodes, model training, inference with Ray, and real-time monitoring using Amazon Managed Prometheus and Grafana.

![Build Model](./assets/GenAI-on-EKS.png)
