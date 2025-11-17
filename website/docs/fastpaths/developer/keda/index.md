---
title: "Autoscaling applications"
chapter: true
sidebar_position: 80
description: "Automatically scale workloads on Amazon Elastic Kubernetes Service with KEDA"
---

:::tip What's been set up for you
After the Amazon EKS Auto Mode cluster was created, an IAM role was configured for the KEDA Operator
:::

Autoscaling monitors your workloads and automatically adjusts capacity to maintain steady, predictable performance while also optimizing for cost. When using Kubernetes there are two main relevant mechanisms which can be used to scale automatically:

- **Compute:** As pods are scaled the underlying compute in a Kubernetes cluster must also adapt by adjusting the number or size of worker nodes used to run the Pods.
- **Pods:** Since pods are used to run workloads in a Kubernetes cluster, scaling a workload is primarily done by scaling Pods either horizontally or vertically in response to scenarios such as changes in load on a given application.

In this lab, we'll look at using the [Kubernetes Event-Driven Autoscaler (KEDA)](https://keda.sh/) to scale pods in a deployment. There is also another option for that purpose, Horizontal Pod Autoscaler (HPA), which can be used to horizontally scale pods based on average CPU utilization. But sometimes workloads need to scale based on external events or metrics. For that, KEDA provides the capability to scale your workload based on events from various event sources, such as the queue length in Amazon SQS or other metrics in CloudWatch. KEDA supports 60+ [scalers](https://keda.sh/docs/scalers/) for various metrics systems, databases, messaging systems, and more.

KEDA is a lightweight workload that can be deployed into a Kubernetes cluster using a Helm chart. KEDA works with standard Kubernetes components like the Horizontal Pod Autoscaler to scale a Deployment or StatefulSet. With KEDA, you selectively choose the workloads you want to scale with these various event sources.
