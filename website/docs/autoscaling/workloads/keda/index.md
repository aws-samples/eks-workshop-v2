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

In this lab, we'll look at using the [Kubernetes Event-Driven Autoscaler (KEDA)](https://keda.sh/) to scale pods in a deployment. In the previous lab on the Horizontal Pod Autoscaler (HPA), we saw how the HPA resource can be used to horizontally scale pods in a deployment based on average CPU utilization. But sometimes workloads need to scale based on external events or metrics. KEDA provides the capability to scale your workload based on events from various event sources, such as the queue length in Amazon SQS or other metrics in CloudWatch. KEDA supports 60+ [scalers](https://keda.sh/docs/scalers/) for various metrics systems, databases, messaging systems, and more.

KEDA is a lightweight workload that can be deployed into a Kubernetes cluster using a Helm chart. KEDA works with standard Kubernetes components like the Horizontal Pod Autoscaler to scale a Deployment or StatefulSet. With KEDA, you selectively choose the workloads you want to scale with these various event sources.
