---
title: "Policy"
sidebar_position: 60
tmdTranslationSourceHash: '9771f0143ec84a1bc572481a9b92f750'
---

[Policy](https://kubernetes.io/docs/concepts/policy/)는 클러스터 리소스 사용량을 정의하고 권장 모범 사례를 충족하기 위해 _Kubernetes Objects_의 배포를 제한합니다. **_Resource Types_** - **_Policy_** 섹션의 클러스터 레벨에서 볼 수 있는 다양한 유형의 정책은 다음과 같습니다:

- Limit Ranges
- Resource Quotas
- Network Policies
- Pod Disruption Budgets
- Pod Security Policies

[LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)는 네임스페이스 내에서 Pod, PersistentVolumeClaim과 같은 각각의 객체 종류에 지정된 리소스 할당(limits 및 requests)을 제한하는 정책입니다. _리소스 할당_은 필요한 리소스를 지정하는 동시에 객체에 의해 리소스가 과도하게 소비되지 않도록 하는 데 사용됩니다. _Karpenter_는 애플리케이션 수요에 따라 적절한 크기의 리소스를 배포하는 데 도움이 되는 Kubernetes 오토스케일러입니다. EKS 클러스터에서 _오토스케일링_을 구성하려면 [Karpenter](../../../fundamentals/compute/karpenter/index.md) 섹션을 참조하세요.

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)는 네임스페이스 레벨에서 정의된 하드 제한이며, `pods`, `services`와 같은 객체 및 `cpu`와 `memory`와 같은 컴퓨팅 리소스는 하드 제한 내에서 생성되어야 하며, 그렇지 않으면 ResourceQuota 객체에 의해 정의된 대로 거부됩니다.

[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)는 소스와 목적지 간의 통신을 설정합니다. 예를 들어 Pod의 `ingress`와 `egress`는 네트워크 정책을 사용하여 제어됩니다.

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)은 삭제, 배포 업데이트, Pod 제거 등과 같이 Pod에 발생할 수 있는 중단을 완화하는 방법입니다. Pod에 발생할 수 있는 _[중단](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_ 유형에 대한 자세한 정보는 링크를 참조하세요.

다음 스크린샷은 네임스페이스별 _PodDisruptionBudgets_ 목록을 표시합니다.

![Insights](/img/resource-view/policy-poddisruption.jpg)

_karpenter_에 대한 _Pod Disruption Budget_을 살펴보겠습니다. 네임스페이스와 이 _Pod Disruption Budget_에 일치해야 하는 매개변수와 같은 이 리소스의 세부 정보를 볼 수 있습니다. 아래 스크린샷에서 `max unavailable = 1`이 설정되어 있는데, 이는 사용 불가능할 수 있는 최대 _karpenter_ Pod 수가 1개임을 의미합니다.

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)

