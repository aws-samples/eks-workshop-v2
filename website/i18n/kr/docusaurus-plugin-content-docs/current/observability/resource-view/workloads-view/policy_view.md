---
title: "정책"
sidebar_position: 60
---

[정책](https://kubernetes.io/docs/concepts/policy/)은 클러스터 리소스 사용을 정의하고 권장 모범 사례를 충족하기 위해 _Kubernetes 객체_ 배포를 제한합니다. 다음은 **_리소스 유형_** - **_정책_** 섹션에서 클러스터 수준에서 볼 수 있는 다양한 유형의 정책입니다.

- 제한 범위
- 리소스 할당량
- 네트워크 정책
- 파드 중단 예산
- 파드 보안 정책

[LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)는 네임스페이스에서 Pod, PersistentVolumeClaim과 같은 각 객체 종류에 지정된 리소스 할당(제한 및 요청)을 제한하는 정책입니다. _리소스 할당_은 필요한 리소스를 지정하고 동시에 객체가 리소스를 과다 소비하지 않도록 보장하는 데 사용됩니다. _Karpenter_는 애플리케이션 수요에 기반하여 적절한 크기의 리소스를 배포하는 데 도움을 주는 Kubernetes 자동 스케일러입니다. EKS 클러스터에서 _자동 스케일링_을 구성하려면 [Karpenter](../../../autoscaling/compute/karpenter/index.md) 섹션을 참조하세요.

[리소스 할당량](https://kubernetes.io/docs/concepts/policy/resource-quotas/)은 네임스페이스 수준에서 정의된 하드 제한이며, `pods`, `services`와 같은 객체와 `cpu` 및 `memory`와 같은 컴퓨팅 리소스는 ResourceQuota 객체에 의해 정의된 하드 제한 내에서 생성되어야 하며, 그렇지 않으면 거부됩니다.

[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)는 소스와 대상 간의 통신을 설정합니다. 예를 들어 파드의 `ingress`와 `egress`는 네트워크 정책을 사용하여 제어됩니다.

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)은 삭제, 배포 업데이트, 파드 제거 등과 같이 파드에 발생할 수 있는 중단을 완화하는 방법입니다. 파드에 발생할 수 있는 _[중단](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_ 유형에 대한 자세한 정보를 확인하세요.

다음 스크린샷은 네임스페이스별 _PodDisruptionBudgets_ 목록을 보여줍니다.

![Insights](/img/resource-view/policy-poddisruption.jpg)

_karpenter_의 _Pod Disruption Budget_을 살펴보면, 네임스페이스와 이 _Pod Disruption Budget_에 대해 일치해야 하는 매개변수와 같은 이 리소스의 세부 정보를 볼 수 있습니다. 아래 스크린샷에서 `max unavailable = 1`로 설정되어 있는데, 이는 사용할 수 없는 _karpenter_ 파드의 최대 수가 1임을 의미합니다.

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)