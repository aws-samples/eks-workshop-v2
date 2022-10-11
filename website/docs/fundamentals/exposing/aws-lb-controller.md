---
title: "AWS Load Balancer Controller"
sidebar_position: 20
---

**AWS Load Balancer Controller** is a [controller](https://kubernetes.io/docs/concepts/architecture/controller/) to help manage Elastic Load Balancers for a Kubernetes cluster.
* It satisfies Kubernetes `Ingress` resources by provisioning Application Load Balancers.
* It satisfies Kubernetes `Service` resources by provisioning Network Load Balancers.

Application Load Balancers work at `L7` of the OSI model, allowing you to expose Kubernetes service using ingress rules, and supports external-facing traffic. Network load balancers work at `L4` of the OSI model, allowing you to leverage Kubernetes `Services` to expose a set of pods as an application network service.