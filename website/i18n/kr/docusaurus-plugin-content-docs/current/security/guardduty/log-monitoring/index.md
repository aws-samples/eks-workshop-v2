---
title: "EKS 로그 모니터링"
sidebar_position: 520
---

EKS 감사 로그 모니터링이 활성화되면 즉시 클러스터의 Kubernetes 감사 로그를 모니터링하고 잠재적으로 악의적이고 의심스러운 활동을 탐지하기 위해 분석을 시작합니다. Amazon EKS 컨트롤 플레인 로깅 기능을 통해 독립적인 플로우 로그 스트림을 통해 Kubernetes 감사 로그 이벤트를 직접 소비합니다.

이 실습에서는 Amazon EKS 클러스터에서 아래 나열된 몇 가지 Kubernetes 감사 모니터링 결과를 생성할 것입니다.

- `Execution:Kubernetes/ExecInKubeSystemPod`
- `Discovery:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AnonymousAccessGranted`
- `Impact:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AdminAccessToDefaultServiceAccount`
- `Policy:Kubernetes/ExposedDashboard`
- `PrivilegeEscalation:Kubernetes/PrivilegedContainer`
- `Persistence:Kubernetes/ContainerWithSensitiveMount`