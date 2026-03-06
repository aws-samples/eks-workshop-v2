---
title: "중단 (통합)"
sidebar_position: 50
tmdTranslationSourceHash: 'c9be6fd2ae61e4dc79f9e05f66ecdc31'
---

Karpenter는 중단 대상인 노드를 자동으로 발견하고 필요한 경우 교체를 생성합니다. 이는 세 가지 다른 이유로 발생할 수 있습니다:

- **만료**: 기본적으로 Karpenter는 720시간(30일) 후 인스턴스를 자동으로 만료시켜 강제로 재생성하여 노드를 최신 상태로 유지합니다.
- **드리프트**: Karpenter는 구성 변경(예: `NodePool` 또는 `EC2NodeClass`)을 감지하여 필요한 변경 사항을 적용합니다.
- **통합**: 비용 효율적인 방식으로 컴퓨팅을 운영하기 위한 중요한 기능으로, Karpenter는 클러스터의 컴퓨팅을 지속적으로 최적화합니다. 예를 들어, 워크로드가 저활용 컴퓨팅 인스턴스에서 실행 중인 경우 더 적은 인스턴스로 통합합니다.

중단은 `NodePool`의 `disruption` 블록을 통해 구성됩니다. 아래 강조 표시된 부분에서 `NodePool`에 이미 구성된 정책을 확인할 수 있습니다.

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.spec.expireAfter,spec.disruption"}

1. `expireAfter`는 사용자 정의 값으로 설정되어 72시간 후 노드가 자동으로 종료됩니다
2. `WhenEmptyOrUnderutilized` 정책은 Karpenter가 노드가 비어 있거나 저활용 상태일 때 교체할 수 있도록 합니다

`consolidationPolicy`는 `WhenEmpty`로도 설정할 수 있으며, 이는 워크로드 Pod가 없는 노드에만 중단을 제한합니다. 중단에 대한 자세한 내용은 [Karpenter 문서](https://karpenter.sh/docs/concepts/disruption/#consolidation)를 참조하세요.

인프라 확장은 비용 효율적인 방식으로 컴퓨팅 인프라를 운영하기 위한 방정식의 한 측면일 뿐입니다. 또한 지속적으로 최적화할 수 있어야 합니다. 예를 들어, 저활용 컴퓨팅 인스턴스에서 실행 중인 워크로드를 더 적은 인스턴스로 압축해야 합니다. 이를 통해 컴퓨팅에서 워크로드를 실행하는 전반적인 효율성이 향상되어 오버헤드가 줄어들고 비용이 절감됩니다.

`disruption`이 `consolidationPolicy: WhenUnderutilized`로 설정된 경우 자동 통합이 트리거되는 방법을 살펴보겠습니다:

1. `inflate` 워크로드를 5개에서 12개 복제본으로 확장하여 Karpenter가 추가 용량을 프로비저닝하도록 트리거
2. 워크로드를 다시 5개 복제본으로 축소
3. Karpenter가 컴퓨팅을 통합하는 것을 관찰

`inflate` 워크로드를 다시 확장하여 더 많은 리소스를 소비하도록 합니다:

```bash
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

이렇게 하면 이 배포의 총 메모리 요청이 약 12Gi로 변경되며, 각 노드의 kubelet을 위해 예약된 약 600Mi를 고려하면 `m5.large` 유형의 인스턴스 2개에 맞춰집니다:

```bash
$ kubectl get nodes -l type=karpenter --label-columns node.kubernetes.io/instance-type
NAME                                         STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   3m30s   vVAR::KUBERNETES_NODE_VERSION     m5.large
ip-10-42-9-102.us-west-2.compute.internal    Ready    <none>   14m     vVAR::KUBERNETES_NODE_VERSION     m5.large
```

다음으로 복제본 수를 다시 5개로 축소합니다:

```bash wait=90
$ kubectl scale -n other deployment/inflate --replicas 5
```

Karpenter 로그를 확인하여 배포 축소에 대한 응답으로 취한 조치를 확인할 수 있습니다. 다음 명령을 실행하기 전에 약 5-10초 정도 기다리세요:

```bash hook=grep
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'disrupting node(s)' | jq '.'
```

출력에는 Karpenter가 차단, 드레인 및 종료할 특정 노드를 식별하는 것이 표시됩니다:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:47:05.659Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

이로 인해 Kubernetes 스케줄러가 해당 노드의 모든 Pod를 나머지 용량에 배치하게 되며, 이제 Karpenter가 총 1개의 노드를 관리하는 것을 확인할 수 있습니다:

```bash
$ kubectl get nodes -l type=karpenter
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   6m30s   vVAR::KUBERNETES_NODE_VERSION   m5.large
```

Karpenter는 워크로드 변경에 대응하여 노드를 더 저렴한 변형으로 교체할 수 있는 경우 추가로 통합할 수도 있습니다. 이는 `inflate` 배포 복제본을 1개로 축소하면 확인할 수 있으며, 총 메모리 요청은 약 1Gi입니다:

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

Karpenter 로그를 확인하여 컨트롤러가 이에 대한 응답으로 취한 조치를 확인할 수 있습니다:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter -f | jq '.'
```

:::tip
이전 명령에는 팔로우를 위한 "-f" 플래그가 포함되어 있어 로그가 발생할 때 이를 확인할 수 있습니다. 더 작은 노드로의 통합은 1분 이내에 완료됩니다. Karpenter 컨트롤러의 동작을 확인하려면 로그를 확인하세요.
:::

출력에는 Karpenter가 교체를 통해 통합하여 m5.large 노드를 Provisioner에 정의된 더 저렴한 c5.large 인스턴스 유형으로 교체하는 것이 표시됩니다:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:50:23.249Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

복제본 1개의 총 메모리 요청이 약 1Gi로 훨씬 낮기 때문에 4GB 메모리를 가진 더 저렴한 c5.large 인스턴스 유형에서 실행하는 것이 더 효율적입니다. 노드가 교체되면 새 노드의 메타데이터를 확인하고 인스턴스 유형이 c5.large인지 확인할 수 있습니다:

```bash
$ kubectl get nodes -l type=karpenter -o jsonpath="{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{'\n'}{end}"
c5.large
```

