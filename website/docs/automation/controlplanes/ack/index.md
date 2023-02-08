---
title: "AWS Controllers for Kubernetes (ACK)"
sidebar_position: 1
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) lets you define and use AWS service resources directly from Kubernetes. 

With ACK, you can take advantage of AWS managed services for your Kubernetes applications without having to define resources outside of the cluster. This reduces the overall complexity for managing the dependencies of your application.

The sample application could be run completely within your cluster, including stateful workloads like database and message queues. This is a good approach when you're developing the application. When the team wants to make the application available in other stages like testing and production, they will use AWS managed services such as Amazon RDS database and Amazon MQ broker. This allows the team to focus on its customers and business projects and not to worry about managing a database or message broker.

In this lab, we'll leverage ACK to provision these services and create secrets and configmaps containing the binding information connecting the application to these AWS managed services.

![EKS with RDS and MQ](./assets/eks-workshop-ack.jpg)
