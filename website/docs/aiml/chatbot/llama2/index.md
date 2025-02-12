---
title: "Understanding the Llama2 Chatbot Model"
sidebar_position: 60
---

Llama2 is a training model that uses FastAPI, Ray Serve, and PyTorch-based Hugging Face Transformers to create a seamless API for text generation.

For this lab, we'll be using Llama-2-13b, a medium-sized model with 13 billion parameters. It offers a good balance between performance and efficiency and can be used for a variety of tasks. Using `Inf2.24xlarge` or `Inf2.48xlarge` instances makes it easier to handle high-performance deep learning (DL) training and inference of generative AI models, including LLMs.

Here's the code for compiling the model that we'll use:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray_serve_llama2.py
```

This Python code performs the following tasks:

1. Configures an APIIngress class responsible for handling inference requests
2. Defines a LlamaModel class responsible for managing the Llama language model
3. Loads and compiles the model based on existing parameters
4. Creates an entry point for the FastAPI application

Through these steps, the Llama-2-13b chat model allows the endpoint to accept input sentences and generate text outputs. The high performance efficiency in processing tasks enables the model to handle a wide variety of natural language processing applications, such as chat bots and text generation tasks.

In this lab, we'll see how the Llama2 Model is configured with Ray Service as a Kubernetes configuration, allowing users to understand how to incorporate fine-tuning and deploy their own natural language processing applications.
