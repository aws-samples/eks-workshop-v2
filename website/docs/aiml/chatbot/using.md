---
title: "Configuring the chat bot"
sidebar_position: 60
---

The sample retail application includes a built-in chat interface that allows customers to interact with the store using natural language. This feature can help customers find products, get recommendations, or answer questions about store policies. For this module, we'll configure this chat component to use our Mistral-7B model served through vLLM.

Let's reconfigure the UI component to enable the chat bot functionality and point it to our vLLM endpoint:

```kustomization
modules/aiml/chatbot/deployment/kustomization.yaml
Deployment/ui
```

This configuration makes the following important changes:

1. Enables the chat bot component in the UI interface
2. Configures the application to use the OpenAI model provider, which works with vLLM's OpenAI-compatible API
3. Specifies the appropriate model name, which is required by the OpenAI endpoint format
4. Sets the endpoint URL to `http://mistral.vllm:8080`, connecting to our Kubernetes Service for the vLLM Deployment

Let's apply these changes to our running application:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

With these changes applied, the UI will now display a chat interface that connects to our locally deployed language model. In the next section, we'll test this configuration to see our AI-powered chat bot in action.

:::note
While the UI is now configured to use the vLLM endpoint, the model needs to be fully loaded before it can respond to requests. If you encounter any delays or errors when testing, this may be because the model is still being initialized.
:::
