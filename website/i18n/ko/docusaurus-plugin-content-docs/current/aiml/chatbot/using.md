---
title: "챗봇 구성하기"
sidebar_position: 60
tmdTranslationSourceHash: 'b928d52fd7b5a0df33f46847cca1ea37'
---

샘플 리테일 애플리케이션에는 고객이 자연어를 사용하여 상점과 상호 작용할 수 있는 내장 채팅 인터페이스가 포함되어 있습니다. 이 기능은 고객이 제품을 찾거나, 추천을 받거나, 상점 정책에 대한 질문에 답하는 데 도움이 될 수 있습니다. 이 모듈에서는 이 채팅 컴포넌트를 vLLM을 통해 제공되는 Mistral-7B 모델을 사용하도록 구성하겠습니다.

챗봇 기능을 활성화하고 vLLM 엔드포인트를 가리키도록 UI 컴포넌트를 재구성해 보겠습니다:

```kustomization
modules/aiml/chatbot/deployment/kustomization.yaml
Deployment/ui
```

이 구성은 다음과 같은 중요한 변경 사항을 적용합니다:

1. UI 인터페이스에서 챗봇 컴포넌트를 활성화합니다
2. vLLM의 OpenAI 호환 API와 작동하는 OpenAI 모델 프로바이더를 사용하도록 애플리케이션을 구성합니다
3. OpenAI 엔드포인트 형식에 필요한 적절한 모델 이름을 지정합니다
4. 엔드포인트 URL을 `http://mistral.vllm:8080`로 설정하여 vLLM Deployment를 위한 Kubernetes Service에 연결합니다

실행 중인 애플리케이션에 이러한 변경 사항을 적용해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

이러한 변경 사항이 적용되면 UI에 로컬로 배포된 언어 모델에 연결되는 채팅 인터페이스가 표시됩니다. 다음 섹션에서는 이 구성을 테스트하여 AI 기반 챗봇이 작동하는 것을 확인하겠습니다.

:::note
UI가 이제 vLLM 엔드포인트를 사용하도록 구성되었지만, 모델이 요청에 응답하려면 완전히 로드되어야 합니다. 테스트 중에 지연이나 오류가 발생하면 모델이 여전히 초기화 중일 수 있습니다.
:::

