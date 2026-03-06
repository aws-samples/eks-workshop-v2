---
title: "AWS Inferentia를 활용한 추론"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 AWS Inferentia를 사용하여 딥러닝 추론 워크로드를 가속화합니다."
tmdTranslationSourceHash: 'c9985ea03c20681a6a0cf025176f16fc'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment aiml/inferentia
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 Karpenter 설치
- 결과를 저장할 S3 버킷 생성
- Pod가 사용할 IAM Role 생성
- [AWS Neuron](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/dlc-then-eks-devflow.html) device plugin 설치

이러한 변경 사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/inferentia/.workshop/terraform)에서 확인할 수 있습니다.

:::

AWS [Trainium](https://aws.amazon.com/machine-learning/trainium/)과 [Inferentia](https://aws.amazon.com/machine-learning/inferentia/)는 클라우드 컴퓨팅 환경에서 AI 모델 훈련과 추론 작업을 각각 가속화하고 최적화하도록 Amazon이 설계한 맞춤형 머신 러닝 가속기입니다.

AWS Neuron은 개발자가 Trainium과 Inferentia 칩 모두에서 머신 러닝 모델을 최적화하고 실행할 수 있게 해주는 소프트웨어 개발 키트(SDK)이자 런타임입니다. Neuron은 이러한 맞춤형 AI 가속기에 통합된 소프트웨어 인터페이스를 제공하여, 개발자가 각 특정 칩 아키텍처에 맞춰 코드를 다시 작성하지 않고도 성능상의 이점을 활용할 수 있게 합니다.

Neuron device plugin은 Neuron 코어와 디바이스를 Kubernetes에 리소스로 노출합니다. 워크로드에 Neuron 코어가 필요한 경우, Kubernetes 스케줄러가 워크로드에 적절한 노드를 할당할 수 있습니다. Karpenter를 사용하여 노드를 자동으로 프로비저닝할 수도 있습니다.

이 실습에서는 EKS에서 Inferentia를 사용하여 딥러닝 추론 워크로드를 가속화하는 방법에 대한 튜토리얼을 제공합니다.

이 실습에서는 다음을 수행합니다:

1. Inferentia 및 Trainium EC2 인스턴스를 프로비저닝하기 위한 Karpenter 노드 풀 생성
2. Trainium 인스턴스를 사용하여 AWS Inferentia에서 사용할 ResNet-50 사전 훈련된 모델 컴파일
3. 나중에 사용할 수 있도록 이 모델을 S3 버킷에 업로드
4. 이전 모델을 사용하여 추론을 실행하는 추론 Pod 실행

시작하겠습니다.

