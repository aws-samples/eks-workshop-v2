---
title: "Ray Serve를 이용한 대규모 언어 모델"
sidebar_position: 30
chapter: true
sidebar_custom_props: { "beta": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 Inferentia를 사용하여 딥러닝 추론 워크로드를 가속화하세요."
---

:::danger
이 모듈은 AWS 이벤트나 Workshop Studio를 통한 AWS 제공 계정에서는 지원되지 않습니다. 이 모듈은 "[In your AWS account](/docs/introduction/setup/your-account)" 단계를 통해 생성된 클러스터에서만 지원됩니다.
:::

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment aiml/chatbot
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon EKS 클러스터에 Karpenter 설치
- Pod가 사용할 IAM 역할 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/chatbot/.workshop/terraform)에서 확인할 수 있습니다.

:::

2조 개의 텍스트와 코드 토큰에 대한 사전 학습을 통해, [Meta Llama-2-13b](https://llama.meta.com/#inside-the-model) 채팅 모델은 현재 사용 가능한 가장 크고 강력한 대규모 언어 모델(LLM) 중 하나입니다.

자연어 처리와 텍스트 생성 능력부터 추론 및 학습 워크로드 처리까지, Llama2의 생성은 GenAI 기술의 최신 발전을 대표합니다.

이 섹션에서는 Llama-2의 성능을 활용할 뿐만 아니라 EKS에서 LLM을 효율적으로 배포하는 복잡한 과정에 대한 통찰력을 얻는 데 중점을 둘 것입니다.

LLM 배포 및 확장을 위해, 이 실습에서는 `Inf2.24xlarge`와 `Inf2.48xlarge`와 같은 [Inf2](https://aws.amazon.com/machine-learning/inferentia/) 제품군의 AWS Inferentia 인스턴스를 활용할 것입니다. 또한, 챗봇 추론 워크로드는 온라인 추론 API 구축과 머신 러닝 모델 배포를 간소화하는 [Ray Serve](https://docs.ray.io/en/latest/serve/index.html) 모듈과 Llama2 챗봇에 접근하기 위한 [Gradio UI](https://www.gradio.app/)를 활용할 것입니다.