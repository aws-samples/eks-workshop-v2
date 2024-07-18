---
title: "Kubernetes Event-Driven Autoscaler (KEDA)"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Automatically scale workloads on Amazon Elastic Kubernetes Service with KEDA"
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/keda
```

This will make the following changes to your lab environment:

- Creates an IAM role required by the AWS Load Balancer Controller
- Deploys Helm chart for AWS Load Balancer Controller
- Creates an IAM role required by the KEDA Operator
- Creates an Ingress resource for the UI workload

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/workloads/keda/.workshop/terraform).

:::

In this lab, we'll look at using the Kubernetes Event-Driven Autoscaler (KEDA) to scale pods in a deployment.
