---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Expose HTTP and HTTPS routes to the outside world using Ingress API on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment exposing/ingress
```

This will make the following changes to your lab environment:

- Create an IAM role required by the AWS Load Balancer Controller
- Create an IAM role required by ExternalDNS
- Create an AWS Route 53 private hosted zone

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/ingress/.workshop/terraform).

:::

Kubernetes Ingress is an API resource that allows you to manage external or internal HTTP(S) access to Kubernetes services running in a cluster. Amazon Elastic Load Balancing Application Load Balancer (ALB) is a popular AWS service that load balances incoming traffic at the application layer (layer 7) across multiple targets, such as Amazon EC2 instances, in a region. ALB supports multiple features including host or path based routing, TLS (Transport Layer Security) termination, WebSockets, HTTP/2, AWS WAF (Web Application Firewall) integration, integrated access logs, and health checks.

In this lab exercise, we'll expose our sample application using an ALB with the Kubernetes ingress model.
