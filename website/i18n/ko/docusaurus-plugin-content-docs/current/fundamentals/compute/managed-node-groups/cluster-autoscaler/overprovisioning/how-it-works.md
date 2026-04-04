---
title: "작동 방식"
sidebar_position: 30
tmdTranslationSourceHash: '94ac3fa1cc182af13143ffc3e7df7f71'
---

Kubernetes는 다른 Pod들과 비교하여 Pod에 우선순위를 할당할 수 있습니다. Kubernetes 스케줄러는 이러한 우선순위를 사용하여 더 높은 우선순위의 Pod를 수용하기 위해 낮은 우선순위의 Pod를 선점합니다. 이는 Pod에 할당할 수 있는 우선순위 값을 정의하는 `PriorityClass` 리소스를 통해 달성됩니다. 또한 기본 `PriorityClass`를 네임스페이스에 할당할 수 있습니다.

다음은 Pod에 다른 Pod들에 비해 상대적으로 높은 우선순위를 부여하는 priority class의 예시입니다:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority Pods only."
```

그리고 다음은 위의 priority class를 사용하는 Pod 사양의 예시입니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
    - name: nginx
      image: nginx
      imagePullPolicy: IfNotPresent
  priorityClassName: high-priority # Priority Class 지정
```

이것이 어떻게 작동하는지에 대한 자세한 설명은 Kubernetes 문서의 [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/)을 참조하세요.

이 개념을 EKS 클러스터의 컴퓨팅 오버프로비저닝에 적용하기 위해 다음 단계를 따를 수 있습니다:

1. 우선순위 값이 **"-1"**인 priority class를 생성하고 이를 빈 [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pod에 할당합니다. 이러한 빈 "pause" 컨테이너는 플레이스홀더 역할을 합니다.

2. 우선순위 값이 **"0"**인 기본 priority class를 생성합니다. 이는 클러스터에 전역적으로 할당되므로 지정된 priority class가 없는 모든 배포에는 이 기본 우선순위가 할당됩니다.

3. 실제 워크로드가 스케줄링되면 빈 플레이스홀더 컨테이너가 축출되어 애플리케이션 Pod가 즉시 프로비저닝될 수 있습니다.

4. 클러스터에 **Pending** (Pause Container) Pod가 있으므로 Cluster Autoscaler는 EKS 노드 그룹과 연결된 **ASG 구성(`--max-size`)**을 기반으로 추가 Kubernetes 워커 노드를 프로비저닝합니다.

오버프로비저닝 수준은 다음을 조정하여 제어할 수 있습니다:

1. pause Pod의 수(**replicas**)와 해당 **CPU 및 memory** 리소스 요청
2. EKS 노드 그룹의 최대 노드 수(`maxsize`)

이 전략을 구현함으로써 클러스터가 항상 새로운 워크로드를 수용할 수 있는 여유 용량을 준비하여 새로운 Pod가 스케줄링 가능하게 되는 데 걸리는 시간을 줄일 수 있습니다.

