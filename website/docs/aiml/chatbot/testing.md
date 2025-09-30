---
title: "Testing the model"
sidebar_position: 70
---

By now the model should be available, or close to it. We can verify this by running the following command, which will block until the model running if it isn't already:

```bash
$ kubectl rollout status --timeout=600s deployment/mistral -n vllm
```

Once the deployment is healthy we can do a simple test of the endpoint with `curl`:

```bash
$ kubectl run curl-test --image=curlimages/curl \
 --rm -itq --restart=Never -- \
 curl http://mistral.vllm:8080/v1/completions \
 -H "Content-Type: application/json" \
 -d '{
    "model": "/models/mistral-7b-v0.3",
    "prompt": "The names of the colors in the rainbow are: ",
    "max_tokens": 100,
    "temperature": 0
}' | jq
{
  "id": "cmpl-af24a0c6ef904f0bb7e2be29e317096b",
  "object": "text_completion",
  "created": 1759208218,
  "model": "/models/mistral-7b-v0.3",
  "choices": [
    {
      "index": 0,
      "text": "1. Red 2. Orange 3. Yellow 4. Green 5. Blue 6. Indigo 7. Violet\n\nThe order of the colors in a rainbow is determined by the wavelength of the light. Red has the longest wavelength, and violet has the shortest. This order is often remembered by the acronym ROYGBIV, which stands for Red, Orange, Yellow, Green, Blue, Indigo, and Violet.",
      "logprobs": null,
      "finish_reason": "length",
      "stop_reason": null,
      "prompt_logprobs": null
    }
  ],
  "usage": {
    "prompt_tokens": 13,
    "total_tokens": 113,
    "completion_tokens": 100,
    "prompt_tokens_details": null
  },
  "kv_transfer_params": null
}
```

In this example we sent the prompt `The names of the colors in the rainbow are:` and the LLM completed this with the text `1. Red 2. Orange 3. Yellow 4. Green 5. Blue [...]`. Due to the non-deterministic nature of LLMs the response you get when running the example may differ.

For a more realistic example we can access the demo web store:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

A "Chat" button will be visible in the bottom-right the screen:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com">
<img src={require('./assets/home-chat.webp').default}/>
</Browser>

Clicking this button will display a chat window which you can use to send messages to the retail store assistant:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com">
<img src={require('./assets/chat-bot.webp').default}/>
</Browser>

We've now demonstrated how to use vLLM to perform inference on Amazon EKS with Trainium instances, and serve a model endpoint that can be consumed by a variety of different end-user applications.
