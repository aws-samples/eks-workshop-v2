---
title: "Accessing workload logs"
sidebar_position: 90
description: "Capture workload logs from pods running on Amazon Elastic Kubernetes Service."
---

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster is configured with Fluent Bit log collection agent.
:::

According to the [Twelve-Factor App manifesto](https://12factor.net/), which provides the gold standard for architecting modern applications, containerized applications should output their [logs to stdout and stderr](https://12factor.net/logs). This is also considered the best practice in Kubernetes.

Application logs are developers' best friends when they need to debug application behavior. However, Kubernetes doesn’t provide a native solution to collect and store logs out of the box. It just configures the container runtime to save logs in JSON format on the local filesystem. Container runtime – like Docker – redirects containers' `stdout` and `stderr` streams to a logging driver. In Kubernetes, container logs are written to `/var/log/pods/*.log` on the node. These logs can be accessed using `kubectl logs myapp` command, where `myapp` is a pod or a deployment running in the cluster. But accessing logs in this manner is not scalable in production. For that, we need a cluster-wide log collector system like Fluent Bit that can tail these log files on the node and ship logs to a log retention and searching system like CloudWatch. These log collector systems usually run as DaemonSets on worker nodes.

In this lab, we'll show how a log agent, Fluent Bit, can be set up to collect application logs from nodes in EKS and send them to CloudWatch Logs.

:::info
If you are using the CDK Observability Accelerator then check out the [AWS for Fluent Bit Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-for-fluent-bit/). AWS for FluentBit addon can be configured to forward logs to multiple AWS destinations including CloudWatch, Amazon Kinesis, and AWS OpenSearch.
:::
