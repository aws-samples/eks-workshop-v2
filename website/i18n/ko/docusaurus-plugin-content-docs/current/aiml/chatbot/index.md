---
title: "vLLM을 사용한 대규모 언어 모델"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "AWS Neuron을 사용하여 Amazon Elastic Kubernetes Service에서 딥러닝 추론 워크로드를 가속화합니다."
tmdTranslationSourceHash: dbd830aa0ebaeea17492897a84a2d888
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment aiml/chatbot
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 Karpenter 설치
- Amazon EKS 클러스터에 AWS Load Balancer Controller 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/chatbot/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Mistral 7B](https://mistral.ai/en/news/announcing-mistral-7b)는 73억 개의 파라미터를 가진 오픈소스 대규모 언어 모델(LLM)로, 성능과 효율성의 균형을 제공하도록 설계되었습니다. 방대한 컴퓨팅 리소스가 필요한 대형 모델과 달리, Mistral 7B는 더 배포 가능한 패키지로 인상적인 기능을 제공합니다. 실용적인 리소스 요구 사항을 유지하면서 텍스트 생성, 완성, 정보 추출, 데이터 분석 및 복잡한 추론 작업에 뛰어난 성능을 발휘합니다.

이 모듈에서는 Amazon EKS에서 Mistral 7B를 배포하고 효율적으로 제공하는 방법을 살펴봅니다. 다음 내용을 학습하게 됩니다:

1. 가속화된 ML 워크로드를 위한 필요한 인프라 설정
2. AWS Trainium accelerator를 사용한 모델 배포
3. 모델 추론 엔드포인트 구성 및 확장
4. 배포된 모델과 간단한 채팅 인터페이스 통합

모델 추론 가속화를 위해 [Trn1](https://aws.amazon.com/ai/machine-learning/trainium/) 인스턴스 패밀리를 통해 AWS Trainium을 활용합니다. 이러한 전용 accelerator는 딥러닝 워크로드에 최적화되어 있으며, 표준 CPU 기반 솔루션에 비해 모델 추론에서 상당한 성능 향상을 제공합니다.

추론 아키텍처는 LLM을 위해 특별히 설계된 높은 처리량과 메모리 효율적인 추론 엔진인 [vLLM](https://github.com/vllm-project/vllm)을 활용합니다. vLLM은 기존 애플리케이션과 쉽게 통합할 수 있는 OpenAI 호환 API 엔드포인트를 제공합니다.

