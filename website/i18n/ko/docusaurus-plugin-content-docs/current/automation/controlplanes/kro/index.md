---
title: "kro - Kube Resource Orchestrator"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 kro를 사용하여 복잡한 Kubernetes 리소스 그래프를 구성하고 관리합니다."
tmdTranslationSourceHash: '323089b6c7dc70bb60357518ab54bc97'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment automation/controlplanes/kro
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- EKS, IAM 및 DynamoDB를 위한 AWS Controllers for Kubernetes 컨트롤러 설치
- AWS Load Balancer Controller 설치
- UI 워크로드를 위한 Ingress 리소스 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/kro/.workshop/terraform)에서 확인할 수 있습니다.

:::

[kro (Kube Resource Orchestrator)](https://kro.run/)는 관련된 Kubernetes 리소스 그룹을 생성하기 위한 사용자 정의 API를 정의할 수 있는 오픈 소스 Kubernetes 오퍼레이터입니다. kro를 사용하면 CEL(Common Expression Language) 표현식을 사용하여 리소스 간의 관계를 정의하고 생성 순서를 자동으로 결정하는 ResourceGraphDefinition(RGD)을 생성할 수 있습니다.

kro를 사용하면 여러 Kubernetes 리소스를 지능적인 종속성 처리가 포함된 상위 수준의 추상화로 구성할 수 있습니다. 리소스가 서로를 참조하는 방식을 분석하여 리소스를 배포할 올바른 순서를 자동으로 결정합니다. CEL 표현식을 사용하여 리소스 간에 값을 전달하고, 조건부 로직을 포함하며, 기본값을 정의하여 사용자 경험을 단순화할 수 있습니다.

이 실습에서는 먼저 WebApplication ResourceGraphDefinition을 사용하여 인메모리 데이터베이스가 포함된 완전한 **Carts** 컴포넌트를 배포하여 kro의 기능을 살펴봅니다. 그런 다음 기본 WebApplication 템플릿을 기반으로 하여 Amazon DynamoDB 스토리지를 추가하는 WebApplicationDynamoDB ResourceGraphDefinition을 구성하여 이를 향상시킵니다.

