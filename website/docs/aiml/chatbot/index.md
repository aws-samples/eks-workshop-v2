---
title: "Large Language Models with Ray Serve"
sidebar_position: 30
chapter: true
sidebar_custom_props: { "beta": true }
description: "Use Inferentia to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::danger
This module is not supported at AWS events or in AWS-vended accounts through Workshop Studio. This module is only supported for clusters created through the "[In your AWS account](http://localhost:3000/docs/introduction/setup/your-account/)" steps.
:::

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

With pre-training on 2 trillion tokens of text and code, the [Meta Llama-2-13b](https://llama.meta.com/#inside-the-model) chat model is one of the largest and most powerful large language models (LLMs) available today.

From its natural language processing and text generation capabilities to handling inference and training workloads, the creation of Llama2 represents some of the newest advances in GenAI Technology.

This section will focus not only on harnessing the power of Llama-2 but also on gaining insights into the intricacies of deploying LLMs efficiently on EKS.

For deploying and scaling LLMs, this lab will utilize AWS Inferentia instances within the [Inf2](https://aws.amazon.com/machine-learning/inferentia/) family, such as `Inf2.24xlarge` and `Inf2.48xlarge`. Additionally, the chatbot inference workloads will utilize the [Ray Serve](https://docs.ray.io/en/latest/serve/index.html) module for building online inference APIs and streamlining the deployment of machine learning models, as well as the [Gradio UI](https://www.gradio.app/) for accessing the Llama2 chatbot.
