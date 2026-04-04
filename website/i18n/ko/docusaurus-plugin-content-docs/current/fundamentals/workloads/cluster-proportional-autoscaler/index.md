---
title: "Cluster Proportional Autoscaler"
sidebar_position: 15
sidebar_custom_props: { "module": true }
description: "Cluster Proportional Autoscaler를 사용하여 Amazon Elastic Kubernetes Service 클러스터 크기에 비례하여 워크로드를 확장합니다."
tmdTranslationSourceHash: fe1dc05aeb82228068bee57790e9b8ef
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/cpa
```

:::

이 실습에서는 [Cluster Proportional Autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler)와 클러스터 컴퓨팅 크기에 비례하여 애플리케이션을 확장하는 방법에 대해 알아봅니다.

Cluster Proportional Autoscaler(CPA)는 클러스터의 노드 수를 기반으로 replica를 확장하는 horizontal pod autoscaler입니다. proportional autoscaler 컨테이너는 클러스터의 스케줄 가능한 노드 수와 코어 수를 모니터링하고 그에 따라 replica 수를 조정합니다. 이 기능은 CoreDNS 및 클러스터의 노드/Pod 수에 따라 확장되어야 하는 기타 서비스와 같이 클러스터 크기에 따라 오토스케일링되어야 하는 애플리케이션에 유용합니다.

CPA는 API Server에 연결하고 클러스터의 노드 및 코어 수를 폴링하는 Golang API 클라이언트를 Pod 내에서 실행하여 작동합니다. 확장 파라미터와 데이터 포인트는 ConfigMap을 통해 autoscaler에 제공되며, autoscaler는 최신 원하는 확장 파라미터를 사용하기 위해 매 폴링 간격마다 파라미터 테이블을 새로 고칩니다. 다른 autoscaler와 달리 CPA는 Metrics API에 의존하지 않으며 Metrics Server가 필요하지 않습니다.

![CPA](/docs/fundamentals/workloads/cluster-proportional-autoscaler/cpa.webp)

CPA의 주요 사용 사례는 다음과 같습니다:

- 과도한 프로비저닝
- 핵심 플랫폼 서비스 확장
- metrics server나 prometheus adapter가 필요하지 않아 워크로드를 확장하는 간단하고 쉬운 메커니즘

## Cluster Proportional Autoscaler에서 사용하는 확장 방법

### Linear

- 이 확장 방법은 클러스터에서 사용 가능한 노드 또는 코어 수에 직접 비례하여 애플리케이션을 확장합니다
- `coresPerReplica` 또는 `nodesPerReplica` 중 하나를 생략할 수 있습니다
- `preventSinglePointFailure`가 `true`로 설정되면 컨트롤러는 노드가 두 개 이상일 경우 최소 2개의 replica를 보장합니다
- `includeUnschedulableNodes`가 `true`로 설정되면 replica는 전체 노드 수를 기반으로 확장됩니다. 그렇지 않으면 replica는 스케줄 가능한 노드 수를 기반으로만 확장됩니다(즉, cordon 및 draining 중인 노드는 제외됨)
- `min`, `max`, `preventSinglePointFailure`, `includeUnschedulableNodes`는 모두 선택 사항입니다. 설정하지 않으면 `min`은 기본값 1로, `preventSinglePointFailure`는 기본값 `false`로, `includeUnschedulableNodes`는 기본값 `false`로 설정됩니다
- `coresPerReplica`와 `nodesPerReplica`는 모두 float 값입니다

### Linear용 ConfigMap

```text
data:
  linear: |-
    {
      "coresPerReplica": 2,
      "nodesPerReplica": 1,
      "min": 1,
      "max": 100,
      "preventSinglePointFailure": true,
      "includeUnschedulableNodes": true
    }
```

**Linear 제어 모드의 방정식:**

```text
replicas = max( ceil( cores * 1/coresPerReplica ) , ceil( nodes * 1/nodesPerReplica ) )
replicas = min(replicas, max)
replicas = max(replicas, min)
```

### Ladder

- 이 확장 방법은 step function을 사용하여 nodes:replicas 및/또는 cores:replicas의 비율을 결정합니다
- step ladder function은 ConfigMap의 core 및 node 확장에 대한 데이터 포인트를 사용합니다. 더 많은 수의 replica를 산출하는 조회가 대상 확장 수로 사용됩니다
- `coresPerReplica` 또는 `nodesPerReplica` 중 하나를 생략할 수 있습니다
- Replica는 0으로 설정할 수 있습니다(linear 모드와 달리)
- 0으로 확장하는 것은 클러스터가 성장함에 따라 선택적 기능을 활성화하는 데 사용할 수 있습니다

### Ladder용 ConfigMap

```text
data:
  ladder: |-
    {
      "coresToReplicas":
      [
        [ 1, 1 ],
        [ 64, 3 ],
        [ 512, 5 ],
        [ 1024, 7 ],
        [ 2048, 10 ],
        [ 4096, 15 ]
      ],
      "nodesToReplicas":
      [
        [ 1, 1 ],
        [ 2, 2 ]
      ]
    }
```

### Horizontal Pod Autoscaler와의 비교

Horizontal Pod Autoscaler는 최상위 Kubernetes API 리소스입니다. HPA는 Pod의 CPU/메모리 사용률을 모니터링하고 replica 수를 자동으로 확장하는 closed feedback loop autoscaler입니다. HPA는 Metrics API에 의존하며 Metrics Server가 필요한 반면, Cluster Proportional Autoscaler는 Metrics Server나 Metrics API를 사용하지 않습니다.

Cluster Proportional Autoscaler는 Kubernetes 리소스로 구성되지 않고 대신 플래그를 사용하여 대상 워크로드를 식별하고 ConfigMap을 사용하여 확장 구성을 설정합니다. CPA는 클러스터 크기를 모니터링하고 대상 컨트롤러를 확장하는 간단한 제어 루프를 제공합니다. CPA의 입력은 클러스터에서 스케줄 가능한 코어 및 노드의 수입니다.

이 실습에서는 EKS 클러스터의 CoreDNS 시스템 컴포넌트를 클러스터의 컴퓨팅 양에 비례하여 확장하는 방법을 시연합니다.

