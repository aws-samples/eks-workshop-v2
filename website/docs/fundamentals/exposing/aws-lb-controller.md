---
title: "AWS Load Balancer Controller"
sidebar_position: 20
---

**AWS Load Balancer Controller** is a [controller](https://kubernetes.io/docs/concepts/architecture/controller/) to help manage Elastic Load Balancers for a Kubernetes cluster.

The controller can provision the following resources:

- An AWS Application Load Balancer when you create a Kubernetes `Ingress`.
- An AWS Network Load Balancer when you create a Kubernetes `Service` of type `LoadBalancer`.

Application Load Balancers work at `L7` of the OSI model, allowing you to expose Kubernetes service using ingress rules, and supports external-facing traffic. Network load balancers work at `L4` of the OSI model, allowing you to leverage Kubernetes `Services` to expose a set of pods as an application network service.

The controller enables you to simplify operations and save costs by sharing an Application Load Balancer across multiple applications in your Kubernetes cluster.

The steps to install the AWS Load Balancer Controller will be presented in the subsequent section, enabling you to get started with creating Load Balancer resources in AWS.

:::info
The AWS Load Balancer Controller was formerly named the AWS ALB Ingress Controller.
:::
