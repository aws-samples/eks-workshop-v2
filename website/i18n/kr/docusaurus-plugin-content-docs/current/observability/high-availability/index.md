---
title: "EKS를 이용한 카오스 엔지니어링"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: Amazon EKS 클러스터의 복원력을 확인하기 위한 다양한 장애 시나리오 시뮬레이션
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=900 wait=30
$ prepare-environment observability/resiliency
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- 인그레스 로드 밸런서 생성
- RBAC 및 롤바인딩 생성 
- AWS Load Balancer 컨트롤러 설치
- AWS Fault Injection Simulator(FIS)를 위한 IAM 역할 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/.workshop/terraform)에서 확인할 수 있습니다.
:::

## 복원력이란 무엇인가?

클라우드 컴퓨팅에서 복원력은 장애와 정상 운영에 대한 도전과제에 직면했을 때 허용 가능한 성능 수준을 유지하는 시스템의 능력을 의미합니다. 다음과 같은 요소를 포함합니다:

1. **장애 허용성**: 일부 구성 요소가 실패하더라도 적절하게 작동을 계속할 수 있는 능력
2. **자가 치유**: 장애를 자동으로 감지하고 복구하는 능력
3. **확장성**: 리소스를 추가하여 증가된 부하를 처리할 수 있는 능력
4. **재해 복구**: 잠재적 재해에 대비하고 복구하는 프로세스

## EKS에서 복원력이 중요한 이유는?

Amazon EKS는 관리형 쿠버네티스 플랫폼을 제공하지만, 복원력 있는 아키텍처를 설계하고 구현하는 것은 여전히 중요합니다. 그 이유는 다음과 같습니다:

1. **고가용성**: 부분적인 시스템 장애 시에도 애플리케이션이 접근 가능하도록 보장
2. **데이터 무결성**: 예기치 않은 이벤트 발생 시 데이터 손실 방지 및 일관성 유지
3. **사용자 경험**: 다운타임과 성능 저하를 최소화하여 사용자 만족도 유지
4. **비용 효율성**: 가변적인 부하와 부분 장애를 처리할 수 있는 시스템을 구축하여 과도한 프로비저닝 방지
5. **규정 준수**: 다양한 산업에서 가동 시간과 데이터 보호에 대한 규제 요구사항 충족

## 실습 개요 및 복원력 시나리오

이 실습에서는 다양한 고가용성 시나리오를 살펴보고 EKS 환경의 복원력을 테스트할 것입니다. 일련의 실험을 통해 다양한 유형의 장애를 처리하고 쿠버네티스 클러스터가 이러한 도전과제에 어떻게 대응하는지 이해하는 실무 경험을 얻게 됩니다.

시뮬레이션하고 대응할 내용:

1. **파드 장애**: ChaosMesh를 사용하여 개별 파드 장애에 대한 애플리케이션의 복원력 테스트
2. **노드 장애**: 쿠버네티스의 자가 치유 기능을 관찰하기 위한 노드 장애 시뮬레이션

   - AWS Fault Injection Simulator 없이: 쿠버네티스의 자가 치유 기능을 관찰하기 위한 수동 노드 장애 시뮬레이션
   - AWS Fault Injection Simulator 사용: AWS Fault Injection Simulator를 활용한 부분 및 전체 노드 장애 시나리오

3. **가용 영역 장애**: 멀티-AZ 배포 전략을 검증하기 위한 전체 AZ 손실 시뮬레이션

## 학습 내용

이 장을 마치면 다음을 할 수 있게 됩니다:

- AWS Fault Injection Simulator(FIS)를 사용하여 제어된 장애 시나리오를 시뮬레이션하고 학습
- 쿠버네티스가 다양한 유형의 장애(파드, 노드, 가용 영역)를 처리하는 방법 이해
- 실제 쿠버네티스의 자가 치유 기능 관찰
- EKS 환경에서의 카오스 엔지니어링 실무 경험 획득

이러한 실험들은 다음을 이해하는데 도움이 됩니다:

- 쿠버네티스가 다양한 유형의 장애를 처리하는 방법
- 적절한 리소스 할당과 파드 분배의 중요성
- 모니터링 및 경고 시스템의 효과성
- 애플리케이션의 장애 허용성과 복구 전략을 개선하는 방법

## 도구 및 기술

이 장에서는 다음을 사용할 것입니다:

- 제어된 카오스 엔지니어링을 위한 AWS Fault Injection Simulator(FIS)
- 쿠버네티스 네이티브 카오스 테스트를 위한 Chaos Mesh
- 카나리 생성 및 모니터링을 위한 AWS CloudWatch Synthetics
- 장애 발생 시 파드와 노드 동작을 관찰하기 위한 쿠버네티스 네이티브 기능

## 카오스 엔지니어링의 중요성

카오스 엔지니어링은 시스템의 약점을 식별하기 위해 의도적으로 제어된 장애를 도입하는 실천입니다. 시스템의 복원력을 사전에 테스트함으로써 다음과 같은 이점을 얻을 수 있습니다:

1. 사용자에게 영향을 미치기 전에 숨겨진 문제 발견
2. 시스템이 불안정한 조건을 견딜 수 있다는 신뢰 구축
3. 사고 대응 절차 개선
4. 조직 내 복원력 문화 조성

이 실습을 마치면 EKS 환경의 고가용성 기능과 잠재적 개선 영역에 대한 포괄적인 이해를 갖게 될 것입니다.

:::info
AWS 복원력 기능에 대한 더 자세한 정보는 다음을 참조하세요:

- [인그레스 로드 밸런서](/docs/fundamentals/exposing/ingress/)
- [쿠버네티스 RBAC와의 통합](/docs/security/cluster-access-management/kubernetes-rbac)
- [AWS Fault Injection Simulator](https://aws.amazon.com/fis/)
- [Amazon EKS에서 복원력 있는 워크로드 운영](https://aws.amazon.com/blogs/containers/operating-resilient-workloads-on-amazon-eks/)

:::