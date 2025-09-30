---
title: "Large Language Models with vLLM"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Trainium to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
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

[Mistral 7B](https://mistral.ai/en/news/announcing-mistral-7b), a 7.3B parameter model, is a powerful language model. It represents a significant advancement in language model technology, combining powerful capabilities like text generation and completion, information extraction, data analysis, API interactions and complex reasoning tasks with practical efficiency.

This section will focus on gaining insights into the intricacies of deploying LLMs efficiently on EKS.

For deploying and scaling the model, this lab will utilize AWS Trainium through the [Trn1](https://aws.amazon.com/ai/machine-learning/trainium/) family. Model inference will utilize the [vLLM](https://github.com/vllm-project/vllm) project to serve an HTTP endpoint that can be used to invoke the model.
