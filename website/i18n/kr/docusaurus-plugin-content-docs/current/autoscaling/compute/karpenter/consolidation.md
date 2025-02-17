---
title: "중단 (통합)"
sidebar_position: 50
---
Karpenter는 중단 대상이 될 수 있는 노드를 자동으로 발견하고 필요할 때 대체 노드를 생성합니다. 이는 다음 세 가지 이유로 발생할 수 있습니다:

- **만료(Expiration)**: 기본적으로 Karpenter는 720시간(30일) 후에 인스턴스를 자동으로 만료시켜 노드를 최신 상태로 유지할 수 있도록 강제로 재활용합니다.
- **드리프트(Drift)**: Karpenter는 필요한 변경사항을 적용하기 위해 `NodePool` 또는 `EC2NodeClass`와 같은 구성의 변경사항을 감지합니다.
- **통합(Consolidation)**: 비용 효율적인 방식으로 컴퓨팅을 운영하기 위한 중요한 기능으로, Karpenter는 지속적으로 클러스터의 컴퓨팅을 최적화합니다. 예를 들어, 워크로드가 충분히 활용되지 않는 컴퓨팅 인스턴스에서 실행 중인 경우, 더 적은 수의 인스턴스로 통합합니다.

중단은 `NodePool`의 `disruption` 블록을 통해 구성됩니다. 아래에 강조 표시된 것처럼 우리의 `NodePool`에 이미 구성된 정책을 볼 수 있습니다.

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.spec.expireAfter,spec.disruption"}

1. `expireAfter`는 72시간 후에 노드가 자동으로 종료되도록 사용자 지정 값으로 설정됩니다
2. `WhenEmptyOrUnderutilized` 정책을 사용하여 Karpenter는 노드가 "충분히 활용되지 않거나" 워크로드 파드가 실행 중일 때 노드를 교체합니다

`consolidationPolicy`는 `WhenEmpty`로 설정할 수도 있으며, 이는 워크로드 파드가 없는 노드에만 중단을 제한합니다. [Karpenter 문서](https://karpenter.sh/docs/concepts/disruption/#consolidation)에서 중단에 대해 자세히 알아보세요.

인프라를 확장하는 것은 비용 효율적인 방식으로 컴퓨팅 인프라를 운영하기 위한 방정식의 한 면일 뿐입니다. 또한 지속적으로 최적화하여 예를 들어 충분히 활용되지 않는 컴퓨팅 인스턴스에서 실행되는 워크로드를 더 적은 수의 인스턴스로 압축할 수 있어야 합니다. 이는 컴퓨팅에서 워크로드를 실행하는 전반적인 효율성을 향상시켜 오버헤드를 줄이고 비용을 낮춥니다.

`disruption`이 `consolidationPolicy: WhenUnderutilized`로 설정되었을 때 자동 통합을 트리거하는 방법을 살펴보겠습니다:

1. `inflate` 워크로드를 5개에서 12개 복제본으로 확장하여 Karpenter가 추가 용량을 프로비저닝하도록 트리거
2. 워크로드를 다시 5개 복제본으로 축소
3. Karpenter가 컴퓨팅을 통합하는 것을 관찰

`inflate` 워크로드를 다시 확장하여 더 많은 리소스를 소비하도록 합니다:

```bash
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

이는 이 배포의 총 메모리 요청을 약 `12Gi`로 변경하며, 각 노드에서 `kubelet`을 위해 예약된 약 600Mi를 고려하면 `m5.large` 타입의 2개 인스턴스에 맞게 됩니다:

```bash
$ kubectl get nodes -l type=karpenter --label-columns node.kubernetes.io/instance-type
NAME                                         STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   3m30s   vVAR::KUBERNETES_NODE_VERSION     m5.large
ip-10-42-9-102.us-west-2.compute.internal    Ready    <none>   14m     vVAR::KUBERNETES_NODE_VERSION     m5.large
```

다음으로, 복제본 수를 다시 5개로 축소합니다:

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

배포 축소에 대한 Karpenter의 대응 조치를 확인하기 위해 로그를 확인할 수 있습니다. 다음 명령을 실행하기 전에 5-10초 정도 기다립니다:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'disrupting nodeclaim(s) via delete' | jq '.'
```

출력에는 Karpenter가 특정 노드를 커든(cordon), 드레인(drain) 그리고 종료하기 위해 식별하는 것이 표시됩니다:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:47:05.659Z",
  "logger": "controller.disruption",
  "message": "disrupting via consolidation delete, terminating 1 candidates ip-10-42-44-164.us-west-2.compute.internal/m5.large/on-demand",
  "commit": "1072d3b"
}
```

이로 인해 Kubernetes 스케줄러가 해당 노드의 모든 파드를 남은 용량에 배치하게 되며, 이제 Karpenter가 총 1개의 노드를 관리하는 것을 볼 수 있습니다:

```bash
$ kubectl get nodes -l type=karpenter
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   6m30s   vVAR::KUBERNETES_NODE_VERSION   m5.large
```

Karpenter는 워크로드 변경에 대응하여 노드를 더 저렴한 변형으로 교체하여 추가로 통합할 수도 있습니다. 이는 `inflate` 배포 복제본을 총 메모리 요청이 약 `1Gi`인 1개로 축소하여 보여줄 수 있습니다:

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

Karpenter 로그를 확인하여 컨트롤러가 어떤 조치를 취했는지 볼 수 있습니다:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter -f | jq '.'
```

:::tip
이전 명령에는 로그를 실시간으로 볼 수 있도록 "`-f`" 플래그가 포함되어 있습니다. 더 작은 노드로의 통합은 1분 미만이 소요됩니다. 로그를 보고 Karpenter 컨트롤러가 어떻게 동작하는지 확인하세요.
:::

출력에는 Karpenter가 `m5.large` 노드를 Provisioner에 정의된 더 저렴한 `c5.large` 인스턴스 타입으로 교체하여 통합하는 것이 표시됩니다:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:50:23.249Z",
  "logger": "controller.disruption",
  "message": "disrupting via consolidation replace, terminating 1 candidates ip-10-42-9-102.us-west-2.compute.internal/m5.large/on-demand and replacing with on-demand node from types c5.large",
  "commit": "1072d3b"
}
```

1개 복제본으로 총 메모리 요청이 약 `1Gi`로 훨씬 낮기 때문에, 4GB 메모리를 가진 더 저렴한 `c5.large` 인스턴스 타입에서 실행하는 것이 더 효율적일 것입니다. 노드가 교체되면, 새 노드의 메타데이터를 확인하여 인스턴스 타입이 `c5.large`인지 확인할 수 있습니다:

```bash
$ kubectl get nodes -l type=karpenter -o jsonpath="{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{'\n'}{end}"
c5.large
```
