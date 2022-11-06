---
title: "AWS Controllers for Kubernetes (ACK)"
sidebar_position: 1
---

[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) lets you define and use AWS service resources directly from Kubernetes. 
With ACK, you can take advantage of AWS-managed services for your Kubernetes applications without needing to define resources outside of the cluster or run services that provide supporting capabilities like databases or message queues within the cluster.

In development our application watch store, it uses mysql and activemq deployed as a single pod inside the cluster, for production we want the application to use AWS managed services, such as Amazon RDS and Amazon MQ. In this module we will leverage ACK to provision these services and create
secrets and configmaps containing the binding information to connect to these services using private networking within the same vpc.


![EKS with RDS and MQ](./assets/eks-workshop-ack.jpg)
