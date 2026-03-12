---
title: "모델 테스트"
sidebar_position: 70
tmdTranslationSourceHash: ed526e73ddd313e6ade14a3384c2caac
---

이제 Mistral-7B 모델이 사용 가능하거나 곧 사용 가능해질 것입니다. 다음 명령을 실행하여 이를 확인할 수 있으며, 모델이 아직 실행 중이 아닌 경우 실행될 때까지 대기합니다:

```bash wait=10 timeout=700
$ kubectl rollout status --timeout=600s deployment/mistral -n vllm
```

## 직접 API 호출로 테스트하기

Deployment가 정상 상태가 되면 `curl`을 사용하여 엔드포인트의 간단한 테스트를 수행할 수 있습니다. 이를 통해 모델이 추론 요청을 올바르게 처리할 수 있는지 확인할 수 있습니다.

다음 페이로드를 전송합니다:

```file
manifests/modules/aiml/chatbot/post.json
```

테스트 명령을 실행합니다:

```bash
$ export payload=$(cat ~/environment/eks-workshop/modules/aiml/chatbot/post.json)
$ kubectl run curl-test --image=curlimages/curl \
 --rm -itq --restart=Never -- \
 curl http://mistral.vllm:8080/v1/completions \
 -H "Content-Type: application/json" \
 -d "$payload" | jq
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

이 예제에서는 `The names of the colors in the rainbow are:`라는 프롬프트를 전송했고 LLM이 무지개 색상을 순서대로 설명하는 텍스트로 완성했습니다. LLM의 비결정적 특성으로 인해 받는 응답은 여기에 표시된 것과 약간 다를 수 있으며, 특히 0보다 큰 temperature 값을 사용하는 경우 더욱 그렇습니다.

## 채팅 인터페이스 테스트하기

보다 대화형 경험을 위해 데모 웹 스토어에 접속하여 통합된 채팅 인터페이스를 사용할 수 있습니다:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get ingress ui -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-ui-5ddc3ba496-1812344516.us-west-2.elb.amazonaws.com
```

화면 오른쪽 하단에 "Chat" 버튼이 표시됩니다:

<Browser url="http://k8s-ui-ui-5ddc3ba496-1812344516.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/docs/aiml/chatbot/home-chat.webp').default}/>
</Browser>

이 버튼을 클릭하면 소매점 어시스턴트에게 메시지를 보낼 수 있는 채팅 창이 표시됩니다:

<Browser url="http://k8s-ui-ui-5ddc3ba496-1812344516.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/docs/aiml/chatbot/chat-bot.webp').default}/>
</Browser>

## 결론

이제 Neuron 인스턴스가 있는 Amazon EKS에서 vLLM을 사용하여 추론을 수행하고 다양한 애플리케이션에서 사용할 수 있는 모델 엔드포인트를 제공하는 방법을 성공적으로 시연했습니다. 이 아키텍처는 전용 ML 가속기의 강력함과 Kubernetes의 유연성 및 확장성을 결합하여 애플리케이션에 비용 효율적인 AI 기능을 제공합니다.

vLLM이 제공하는 OpenAI 호환 API를 사용하면 이 솔루션을 기존 애플리케이션 및 프레임워크와 통합하는 것이 간단해지며, 자체 인프라 내에서 대규모 언어 모델을 활용할 수 있습니다.

