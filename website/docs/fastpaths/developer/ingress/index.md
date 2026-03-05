---
title: "Exposing workloads with Ingress"
chapter: true
sidebar_position: 20
description: "Expose HTTP and HTTPS routes to the outside world using Ingress API on Amazon Elastic Kubernetes Service."
---

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes the **AWS Load Balancer Controller**, which manages AWS Elastic Load Balancers for Kubernetes Ingress resources.
:::

Right now our web store application is not exposed to the outside world, so there's no way for users to access it. Although there are many microservices in our web store workload, only the `ui` application needs to be available to end users. This is because the `ui` application will perform all communication to the other backend services using internal Kubernetes networking.

Kubernetes Ingress is an API resource that allows you to manage external or internal HTTP(S) access to Kubernetes services running in a cluster. Amazon Elastic Load Balancing Application Load Balancer (ALB) is a popular AWS service that load balances incoming traffic at the application layer (layer 7) across multiple targets, such as Amazon EC2 instances, in a region. ALB supports multiple features including host or path based routing, TLS (Transport Layer Security) termination, WebSockets, HTTP/2, AWS WAF (Web Application Firewall) integration, integrated access logs, and health checks.

In this lab exercise, we'll expose our sample application using an ALB with the Kubernetes ingress model.
