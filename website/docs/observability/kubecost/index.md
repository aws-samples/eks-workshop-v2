---
title: "Cost visibility with Kubecost"
sidebar_position: 60
sidebar_custom_props: {"module": true}
---

Kubecost provides real-time cost visibility and insights for teams using Kubernetes, helping you continuously reduce your cloud costs.

While you can track Kubernetes control plane and EC2 costs using AWS Cost and Usage Reports, some may need deeper insight. Kubecost allows you to accurately track Kubernetes resources by namespace, cluster, pod, or organizational concepts (e.g., by team or application). This can also be helpful when running a multi tenant cluster environment and need to break down costs by tenant in your cluster. For example, Kubecost allows you to determine the resources used by a specific group of pods, customers have typically had to manually aggregate the compute resource usage for a particular period to calculate the cost. Containers are also often short-lived and scale at various levels, so the resource usage fluctuates over time, further adding complexity to this equation.

This is the exact challenge that Kubecost is dedicated to tackling. Founded in 2019, Kubecost launched to provide customers with visibility into spend and resource efficiency in Kubernetes environments, and today helps thousands of teams address this challenge. Kubecost is built on OpenCost, which was recently accepted as a Cloud Native Computing Foundation (CNCF) Sandbox project, and is actively supported by AWS.

In this chapter, we'll take a look at how to use Kubecost to measure the cost allocation of various components at namespace level, deployment level and pod level. We'll also see the resource efficiency to check whether the deployments are over provisioned or under provisioned, health of the system, etc.
