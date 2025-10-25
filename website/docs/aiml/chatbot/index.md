---
title: "Large Language Models with vLLM"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Use AWS Trainium to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/chatbot
```

This will make the following changes to your lab environment:

- Installs Karpenter in the Amazon EKS cluster
- Installs the AWS Load Balancer Controller in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/chatbot/.workshop/terraform).

:::

[Mistral 7B](https://mistral.ai/en/news/announcing-mistral-7b) is an open-source large language model (LLM) with 7.3 billion parameters designed to provide a balance of performance and efficiency. Unlike larger models that require massive computational resources, Mistral 7B offers impressive capabilities in a more deployable package. It excels at text generation, completion, information extraction, data analysis, and complex reasoning tasks while maintaining practical resource requirements.

In this module, we'll explore how to deploy and efficiently serve Mistral 7B on Amazon EKS. You'll learn how to:

1. Set up the necessary infrastructure for accelerated ML workloads
2. Deploy the model using AWS Trainium accelerators
3. Configure and scale the model inference endpoint
4. Integrate a simple chat interface with the deployed model

For accelerating model inference, we'll leverage AWS Trainium through the [Trn1](https://aws.amazon.com/ai/machine-learning/trainium/) instance family. These purpose-built accelerators are optimized for deep learning workloads and offer significant performance improvements for model inference compared to standard CPU-based solutions.

Our inference architecture will utilize [vLLM](https://github.com/vllm-project/vllm), a high-throughput and memory-efficient inference engine specifically designed for LLMs. vLLM provides an OpenAI-compatible API endpoint that makes it easy to integrate with existing applications.
