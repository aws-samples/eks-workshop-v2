---
title: "AWS Controller Overview"
sidebar_position: 1
weight: 20
---

[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) lets you define and use AWS service resources directly from Kubernetes. 
With ACK, you can take advantage of AWS-managed services for your Kubernetes applications without needing to define resources outside of the cluster or run services that provide supporting capabilities like databases or message queues within the cluster.

In development our application watch store, it uses mysql and activemq deploy as a single pod inside the cluster, for production we want the application to use AWS RDS and Amazon MQ. In this module will leverage ACK to provision these services and create
secrets and configmal containing the binding information that the application will use to connect to this services using private networking within the same vpc.


