---
title: "Llama2 챗봇 모델 이해하기"
sidebar_position: 20
---

Llama2는 FastAPI, Ray Serve 및 PyTorch 기반 Hugging Face Transformers를 사용하여 텍스트 생성을 위한 원활한 API를 만드는 학습 모델입니다.

이 실습에서는 130억 개의 매개변수를 가진 중형 모델인 Llama-2-13b를 사용할 것입니다. 이 모델은 성능과 효율성 사이의 균형이 좋으며 다양한 작업에 사용될 수 있습니다. `Inf2.24xlarge` 또는 `Inf2.48xlarge` 인스턴스를 사용하면 LLM을 포함한 생성형 AI 모델의 고성능 딥러닝(DL) 학습 및 추론을 더 쉽게 처리할 수 있습니다.

다음은 우리가 사용할 모델을 컴파일하는 코드입니다:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray_serve_llama2.py
```

이 Python 코드는 다음과 같은 작업을 수행합니다:

1. 추론 요청을 처리하는 APIIngress 클래스를 구성
2. Llama 언어 모델을 관리하는 LlamaModel 클래스를 정의
3. 기존 매개변수를 기반으로 모델을 로드하고 컴파일
4. FastAPI 애플리케이션의 진입점 생성

이러한 단계를 통해 Llama-2-13b 채팅 모델은 엔드포인트가 입력 문장을 받아들이고 텍스트 출력을 생성할 수 있게 합니다. 작업 처리의 높은 성능 효율성으로 인해 모델은 챗봇 및 텍스트 생성 작업과 같은 다양한 자연어 처리 애플리케이션을 처리할 수 있습니다.

이 실습에서는 Llama2 모델이 Kubernetes 구성으로 Ray Service와 함께 구성되는 방법을 살펴보며, 사용자가 자신만의 자연어 처리 애플리케이션을 미세 조정하고 배포하는 방법을 이해할 수 있게 됩니다.