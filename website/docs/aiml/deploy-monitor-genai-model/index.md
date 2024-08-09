---
title: "Deploy and Monitor GenAI Model on EKS"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Deploy and Monitor GenAI Model on EKS"
---


{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=1800 wait=30
$ prepare-environment aiml/deploy-monitor-genai-model
```

Its takes around 25 mins to complete the initial preparation, this will make the following changes to your lab environment:

 - Creates EKS cluster 
 - Install EBS CSI Driver and AWS Load Balancer controller
 - Installs Amazon Managed Prometheus, Grafana and AWS managed collector
 - Prerequisite IAM roles for Karpenter 

:::


# GenAI on EKS 

Welcome to the "GenAI on Amazon EKS" workshop! In this workshop, we'll cover aspects, from creating an EKS cluster with GPU nodes to model training, inference with Ray, and real-time monitoring using Amazon Managed Prometheus and Grafana.

![Build Model](./assets/GenAI-on-EKS.png)


## High level overview 

 1. Create an EKS cluster, install EBS CSI driver & AWS Load Balancer controller, Amazon Managed Prometheus, Granfana and an AWS managed collector
 2. Install Karpenter, Nvidia GPU Operator and Ray cluster 
 2. Install Jupyterhub notebook and train the model
 4. Create an Inference service using KubeRay service
 5. Monitor the GPU metrics using the Amazon Managed Prometheus and Grafana 

