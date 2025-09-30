---
title: "Configuring the chat bot"
sidebar_position: 60
---

The retail sample application has a simple built-in chat bot that we can use to test the model. Let's reconfigure the UI component to enable the chat bot and use the vLLM model endpoint that will become available.

```kustomization
modules/aiml/chatbot/deployment/kustomization.yaml
Deployment/ui
```

This will re-configure the UI component to:

1. Enable the chat bot component in the UI
2. Use the OpenAI model provider, since vLLM exposes an OpenAI-compatible endpoint
3. Specify the model, which is required by the OpenAI endpoint
4. Use the `http://mistral.vllm:8080` endpoint, which is the Kubernetes Service configured for the vLLM deployment

Apply these changes with the following command:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

Now we can move on to testing our model.
