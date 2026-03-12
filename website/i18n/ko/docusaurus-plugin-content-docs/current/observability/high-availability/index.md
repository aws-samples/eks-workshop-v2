---
title: "EKS로 카오스 엔지니어링"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: Amazon EKS 클러스터 복원력을 확인하기 위한 다양한 장애 시나리오 시뮬레이션"
tmdTranslationSourceHash: f4f02238c6bb6f8894fe29117ebc3102
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=900 wait=30
$ prepare-environment observability/resiliency
```

이는 랩 환경에 다음과 같은 변경 사항을 적용합니다:

- Ingress 로드 밸런서 생성
- RBAC 및 RoleBindings 생성
- AWS Load Balancer controller 설치
- AWS Fault Injection Simulator (FIS)를 위한 IAM role 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/.workshop/terraform)에서 확인할 수 있습니다.
:::

## 복원력이란?

클라우드 컴퓨팅에서 복원력은 장애와 정상 작동에 대한 문제가 발생했을 때 시스템이 허용 가능한 성능 수준을 유지하는 능력을 의미합니다. 이는 다음을 포함합니다:

1. **장애 허용**: 일부 컴포넌트의 장애가 발생했을 때에도 계속 정상적으로 작동할 수 있는 능력.
2. **자가 치유**: 장애를 자동으로 감지하고 복구할 수 있는 능력.
3. **확장성**: 리소스를 추가하여 증가된 부하를 처리할 수 있는 능력.
4. **재해 복구**: 잠재적 재해에 대비하고 복구하는 프로세스.

## EKS에서 복원력이 중요한 이유는?

Amazon EKS는 관리형 Kubernetes 플랫폼을 제공하지만, 복원력 있는 아키텍처를 설계하고 구현하는 것은 여전히 중요합니다. 그 이유는 다음과 같습니다:

1. **고가용성**: 부분적인 시스템 장애 중에도 애플리케이션이 계속 액세스 가능하도록 보장합니다.
2. **데이터 무결성**: 예상치 못한 이벤트 중에 데이터 손실을 방지하고 일관성을 유지합니다.
3. **사용자 경험**: 다운타임과 성능 저하를 최소화하여 사용자 만족도를 유지합니다.
4. **비용 효율성**: 가변 부하와 부분적 장애를 처리할 수 있는 시스템을 구축하여 과도한 프로비저닝을 방지합니다.
5. **컴플라이언스**: 다양한 산업 분야의 가동 시간 및 데이터 보호에 대한 규제 요구 사항을 충족합니다.

## 랩 개요 및 복원력 시나리오

이 랩에서는 다양한 고가용성 시나리오를 탐색하고 EKS 환경의 복원력을 테스트합니다. 일련의 실험을 통해 다양한 유형의 장애를 처리하고 Kubernetes 클러스터가 이러한 문제에 어떻게 대응하는지 이해하는 실습 경험을 얻게 됩니다.

다음을 시뮬레이션하고 대응합니다:

1. **Pod 장애**: ChaosMesh를 사용하여 개별 Pod 장애에 대한 애플리케이션의 복원력을 테스트합니다.
2. **노드 장애**: 노드 장애를 수동으로 시뮬레이션하여 Kubernetes의 자가 치유 능력을 관찰합니다.

   - AWS Fault Injection Simulator 없이: 노드 장애를 수동으로 시뮬레이션하여 Kubernetes의 자가 치유 능력을 관찰합니다.
   - AWS Fault Injection Simulator 사용: 부분적 및 완전한 노드 장애 시나리오를 위해 AWS Fault Injection Simulator를 활용합니다.

3. **가용 영역 장애**: 전체 AZ의 손실을 시뮬레이션하여 다중 AZ 배포 전략을 검증합니다.

## 배울 내용

이 챕터를 마치면 다음을 할 수 있습니다:

- AWS Fault Injection Simulator (FIS)를 사용하여 제어된 장애 시나리오를 시뮬레이션하고 학습하기
- Kubernetes가 다양한 유형의 장애(Pod, 노드, 가용 영역)를 처리하는 방법 이해하기
- Kubernetes의 자가 치유 능력을 실제로 관찰하기
- EKS 환경을 위한 카오스 엔지니어링 실습 경험 얻기

이러한 실험을 통해 다음을 이해할 수 있습니다:

- Kubernetes가 다양한 유형의 장애를 처리하는 방법
- 적절한 리소스 할당 및 Pod 분산의 중요성
- 모니터링 및 알림 시스템의 효과성
- 애플리케이션의 장애 허용 및 복구 전략을 개선하는 방법

## 도구 및 기술

이 챕터 전체에서 다음을 사용합니다:

- 제어된 카오스 엔지니어링을 위한 AWS Fault Injection Simulator (FIS)
- Kubernetes 네이티브 카오스 테스트를 위한 Chaos Mesh
- Canary 생성 및 모니터링을 위한 AWS CloudWatch Synthetics
- 장애 중 Pod 및 노드 동작을 관찰하기 위한 Kubernetes 네이티브 기능

## 카오스 엔지니어링의 중요성

카오스 엔지니어링은 시스템의 약점을 식별하기 위해 의도적으로 제어된 장애를 도입하는 실천입니다. 시스템의 복원력을 능동적으로 테스트함으로써 다음을 할 수 있습니다:

1. 사용자에게 영향을 미치기 전에 숨겨진 문제를 발견
2. 시스템이 불안정한 조건을 견딜 수 있다는 확신 구축
3. 인시던트 대응 절차 개선
4. 조직 내에서 복원력 문화 조성

이 랩을 마치면 EKS 환경의 고가용성 능력과 잠재적 개선 영역에 대한 포괄적인 이해를 갖게 됩니다.

:::info
AWS 복원력 기능에 대한 더 자세한 정보는 다음을 확인하는 것을 권장합니다:

- [Ingress Load Balancer](/docs/fundamentals/exposing/ingress/)
- [Integrating with Kubernetes RBAC](/docs/security/cluster-access-management/kubernetes-rbac)
- [AWS Fault Injection Simulator](https://aws.amazon.com/fis/)
- [Operating resilient workloads on Amazon EKS](https://aws.amazon.com/blogs/containers/operating-resilient-workloads-on-amazon-eks/)

:::

