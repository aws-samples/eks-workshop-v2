---
title: "Understanding the Llama2 Chatbot Model"
sidebar_position: 20
---

Llama2 is presented as a training model that uses FastAPI, Ray Serve, and PyTorch-based Hugging Face Transformers to create seamless API for text generation.

For this lab, we will be using Llama-2-13b, a medium-sized model with 13 billion parameters. It is a good balance between performance and efficiency, and can be used for a variety of tasks. Through using `Inf2.24xlarge` or `Inf2.48xlarge` instances, it makes it easier to handle high-performance deep learning (DL) training and inference of generative AI models, including LLMs.

Here is the code for compiling the model that we will use:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray_serve_llama2.py
```

This Python code does the following tasks:

1. Configures APIIngress class responsible for handling inference requests
2. Defines LlamaModel class responsible for managing the Llama language model
3. Load and compile the model based on existing parameters
4. It then creates an entry point for the FastAPI application

Through these steps, the Llama-2-13b chat model allows for the endpoint to accept input
sentences and then generate text outputs. The high performance efficiency in processing tasks
will allow for the model to handle a wide variety of natural language processing applications,
such as chatbots and text generation tasks.

Within the lab, we will see how the Llama2 Model is configured with Ray Service as a Kubernetes
configuration, allowing for users to understand how to incorporate fine-tuning and deploying
their own natural language processing applications.
