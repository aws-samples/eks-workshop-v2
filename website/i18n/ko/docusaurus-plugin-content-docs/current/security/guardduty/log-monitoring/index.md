---
title: "EKS 로그 모니터링"
sidebar_position: 520
tmdTranslationSourceHash: 'f8634397e9ee0acf471865e8045d50db'
---

EKS Audit Log Monitoring이 활성화되면, 즉시 클러스터의 Kubernetes 감사 로그를 모니터링하기 시작하고 잠재적으로 악의적이고 의심스러운 활동을 감지하기 위해 분석합니다. 이는 독립적인 플로우 로그 스트림을 통해 Amazon EKS 컨트롤 플레인 로깅 기능에서 직접 Kubernetes 감사 로그 이벤트를 수집합니다.

이 실습 연습에서는 Amazon EKS 클러스터에서 아래 목록과 같이 몇 가지 Kubernetes 감사 모니터링 결과를 생성할 것입니다.

- `Execution:Kubernetes/ExecInKubeSystemPod`
- `Discovery:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AnonymousAccessGranted`
- `Impact:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AdminAccessToDefaultServiceAccount`
- `Policy:Kubernetes/ExposedDashboard`
- `PrivilegeEscalation:Kubernetes/PrivilegedContainer`
- `Persistence:Kubernetes/ContainerWithSensitiveMount`

