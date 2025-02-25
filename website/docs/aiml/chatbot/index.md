---
title: "Large Language Models with Ray Serve"
sidebar_position: 30
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Inferentia to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/chatbot
```

This will make the following changes to your lab environment:

- Installs Karpenter in the Amazon EKS cluster
- Creates an IAM Role for the Pods to use

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/chatbot/.workshop/terraform).

:::
[Mistral 7B](https://mistral.ai/en/news/announcing-mistral-7b), a 7.3B parameter model, is one of the most powerful language model for its size to date. It represents a significant advancement in language model technology, combining powerful capabilities like Text generation and completion, Information extraction, Data analysis, API interaction, Complex reasoning tasks with practical efficiency.

This section will focus on gaining insights into the intricacies of deploying LLMs efficiently on EKS.

For deploying and scaling LLMs, this lab will utilize AWS Trainium within the [Trn1](https://aws.amazon.com/ai/machine-learning/trainium/) family, such as `trn1.2xlarge`. Additionally, the chatbot inference workloads will utilize the [Ray Serve](https://docs.ray.io/en/latest/serve/index.html) module for building online inference APIs and streamlining the deployment of machine learning models, as well as the [Gradio UI](https://www.gradio.app/) for accessing the Mistral-7B chatbot.
