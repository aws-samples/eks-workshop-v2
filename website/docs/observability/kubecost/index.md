---
title: "Cost visibility with Kubecost"
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Gain cost visibility and insights for teams using Amazon Elastic Kubernetes Service with Kubecost."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment observability/kubecost
```

This will make the following changes to your lab environment:

- Install the AWS Load Balancer controller in the Amazon EKS cluster
- Install the EKS managed addon for the EBS CSI driver

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/kubecost/.workshop/terraform).

:::

Kubecost provides real-time cost visibility and insights for teams using Kubernetes, helping you continuously reduce your cloud costs.

While you can track Kubernetes control plane and EC2 costs using AWS Cost and Usage Reports, some may need deeper insight. Kubecost allows you to accurately track Kubernetes resources by namespace, cluster, pod, or organizational concepts (e.g., by team or application). This can also be helpful when running a multi tenant cluster environment and need to break down costs by tenant in your cluster. For example, Kubecost allows you to determine the resources used by a specific group of pods, customers have typically had to manually aggregate the compute resource usage for a particular period to calculate the cost. Containers are also often short-lived and scale at various levels, so the resource usage fluctuates over time, further adding complexity to this equation.

This is the exact challenge that Kubecost is dedicated to tackling. Founded in 2019, Kubecost launched to provide customers with visibility into spend and resource efficiency in Kubernetes environments, and today helps thousands of teams address this challenge. Kubecost is built on OpenCost, which was recently accepted as a Cloud Native Computing Foundation (CNCF) Sandbox project, and is actively supported by AWS.

In this chapter, we'll take a look at how to use Kubecost to measure the cost allocation of various components at namespace level, deployment level and pod level. We'll also see the resource efficiency to check whether the deployments are over provisioned or under provisioned, health of the system, etc.

:::tip
After completing this module checkout how to use Kubecost and [Amazon Managed Service for Prometheus](https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html) to extend cost visibility beyond a single EKS cluster with [Multi-Cluster Cost Monitoring](https://aws.amazon.com/blogs/containers/multi-cluster-cost-monitoring-using-kubecost-with-amazon-eks-and-amazon-managed-service-for-prometheus/). Learn how to [secure access to Kubecost dashboard using Amazon Cognito](https://aws.amazon.com/blogs/containers/securing-kubecost-access-with-amazon-cognito/).

:::

:::info
If you are using the CDK Observability Accelerator then check out the [Kubecost Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/kubecost/). The addon greatly simplifies the process of setting up Kubecost and AMP for your EKS clusters.
:::
