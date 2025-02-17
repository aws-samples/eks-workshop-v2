---
title: "작동 방식"
sidebar_position: 30
---

Kubernetes는 다른 Pod들과 비교하여 Pod에 우선순위를 할당할 수 있습니다. Kubernetes 스케줄러는 이러한 우선순위를 사용하여 우선순위가 높은 Pod를 수용하기 위해 우선순위가 낮은 Pod를 선점합니다. 이는 Pod에 할당할 수 있는 우선순위 값을 정의하는 `PriorityClass` 리소스를 통해 달성됩니다. 또한 네임스페이스에 기본 `PriorityClass`를 할당할 수 있습니다.

다음은 다른 Pod들보다 상대적으로 높은 우선순위를 Pod에 부여하는 우선순위 클래스의 예시입니다:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority Pods only."
```

그리고 위의 우선순위 클래스를 사용하는 Pod 명세의 예시입니다:

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
  priorityClassName: high-priority # Priority Class specified
```

이것이 어떻게 작동하는지에 대한 자세한 설명은 Kubernetes 문서의 [Pod 우선순위와 선점](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/)을 참조하십시오.

EKS 클러스터에서 컴퓨팅 자원을 오버프로비저닝하기 위해 이 개념을 적용하려면 다음 단계를 따를 수 있습니다:

1. **"-1"** 우선순위 값을 가진 우선순위 클래스를 생성하고 이를 빈 [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pod에 할당합니다. 이러한 빈 "pause" 컨테이너는 자리 표시자 역할을 합니다.

2. **"0"** 우선순위 값을 가진 기본 우선순위 클래스를 생성합니다. 이는 클러스터 전체에 전역적으로 할당되므로, 지정된 우선순위 클래스가 없는 모든 배포에 이 기본 우선순위가 할당됩니다.

3. 실제 워크로드가 스케줄링될 때, 빈 자리 표시자 컨테이너가 제거되어 애플리케이션 Pod가 즉시 프로비저닝될 수 있습니다.

4. 클러스터에 **대기 중인**(Pause Container) Pod가 있기 때문에, Cluster Autoscaler는 EKS 노드 그룹과 연관된 **ASG 구성(`--max-size`)**을 기반으로 추가 Kubernetes 워커 노드를 프로비저닝합니다.

오버프로비저닝 수준은 다음을 조정하여 제어할 수 있습니다:

1. pause Pod의 수(**replicas**)와 그들의 **CPU 및 메모리** 리소스 요청
2. EKS 노드 그룹의 최대 노드 수(`maxsize`)

이 전략을 구현함으로써, 클러스터가 항상 새로운 워크로드를 수용할 수 있는 여분의 용량을 가지고 있도록 보장하여, 새로운 Pod가 스케줄 가능해지는 데 걸리는 시간을 줄일 수 있습니다.