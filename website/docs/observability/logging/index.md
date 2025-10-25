---
title: "Logging in EKS"
sidebar_position: 30
---

Kubernetes logging can be divided into control plane logging, node logging, and application logging. The [Kubernetes control plane](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components) is a set of components that manage Kubernetes clusters and produce logs used for auditing and diagnostic purposes. With Amazon EKS, you can turn on logs for different control plane components and send them to Amazon CloudWatch.

Containers are grouped as Pods within a Kubernetes cluster and are scheduled to run on your Kubernetes nodes. Most containerized applications write to standard output and standard error, and the container engine redirects the output to a logging driver. In Kubernetes, the container logs are found in the `/var/log/pods` directory on a node. You can configure CloudWatch and Container Insights to capture these logs for each of your Amazon EKS pods.

In this lab, we'll see

- How to enable EKS Control Plane logs and verify it in the Amazon CloudWatch
- How to setup the logging agent (Fluent Bit) to stream the Pod logs to Amazon CloudWatch
