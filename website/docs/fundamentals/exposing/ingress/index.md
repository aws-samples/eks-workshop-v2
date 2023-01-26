---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

Kubernetes Ingress is an API resource that allows you manage external or internal HTTP(S) access to Kubernetes services running in a cluster. Amazon Elastic Load Balancing Application Load Balancer (ALB) is a popular AWS service that load balances incoming traffic at the application layer (layer 7) across multiple targets, such as Amazon EC2 instances, in a region. ALB supports multiple features including host or path based routing, TLS (Transport Layer Security) termination, WebSockets, HTTP/2, AWS WAF (Web Application Firewall) integration, integrated access logs, and health checks.

In this lab exercise, we'll expose our sample application using an ALB with the Kubernetes ingress model.
