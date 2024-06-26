---
title: "Run Chatbot using AWS Inferentia, Ray Serve, Gradio on Amazon EKS"
sidebar_position: 30
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Inferentia to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/inferentia
```

This will make the following changes to your lab environment:

- Installs Karpenter in the Amazon EKS cluster
- Creates an S3 Bucket to store results
- Creates an IAM Role for the Pods to use
- Installs the [AWS Neuron](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/dlc-then-eks-devflow.html) device plugin

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/inferentia/.workshop/terraform).

:::

Welcome to the comprehensive guide on deploying the Meta Llama-2-13b chat model on Amazon Elastic Kubernetes Service (EKS) using Ray Serve. In this section, you will not only learn how to harness the power of Llama-2, but also gain insights into the intricacies of deploying large language models (LLMs) efficiently, particularly on inf2 (powered by AWS Inferentia) instances, such as inf2.24xlarge and inf2.48xlarge, which are optimized for deploying and scaling large language models.
