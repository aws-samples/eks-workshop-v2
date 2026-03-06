---
title: "클라우드 버스팅"
sidebar_position: 20
sidebar_custom_props: { "module": false }
weight: 30 # used by test framework
tmdTranslationSourceHash: '90c208a2d82f217beae9075819d3cc65'
---

이전 배포를 기반으로, 이제 "클라우드 버스팅" 사용 사례를 시뮬레이션하는 시나리오를 살펴보겠습니다. 이는 EKS Hybrid Nodes에서 실행되는 워크로드가 수요가 최고조일 때 탄력적인 클라우드 용량을 사용하여 EC2 노드로 "버스팅"할 수 있는 방법을 보여줍니다.

이전 예제와 마찬가지로 하이브리드 노드를 선호하도록 `nodeAffinity`를 사용하는 새로운 워크로드를 배포하겠습니다. `preferredDuringSchedulingIgnoredDuringExecution` 전략은 Kubernetes에게 스케줄링할 때 Hybrid Node를 _선호_하지만 실행 중에는 _무시_하도록 지시합니다.
이는 단일 하이브리드 노드에 더 이상 공간이 없을 때, 이러한 Pod들이
클러스터의 다른 곳, 즉 EC2 인스턴스에 자유롭게 스케줄링될 수 있음을 의미합니다. 이는
훌륭합니다! 원하는 클라우드 버스팅을 제공합니다. 그러나
_IgnoredDuringExecution_ 부분은 스케일을 다시 줄일 때 Kubernetes가
실행 중에는 _무시_되기 때문에 Pod가 실행되는 위치를 신경 쓰지 않고 무작위로 Pod를 제거한다는 것을 의미합니다. 일반적으로 Kubernetes는
먼저 오래된 Pod를 제거하는데, 이는 Hybrid Nodes에서 실행 중인 Pod가 될 것입니다. 우리는
그것을 원하지 않습니다!

Kubernetes를 위한 정책 엔진인 [Kyverno](https://kyverno.io/)를 배포할 것입니다. Kyverno는
하이브리드 노드로 스케줄링된 Pod(`eks.amazonaws.com/compute-type: hybrid` 레이블이 지정됨)를 감시하고, 실행 중인
Pod에 Annotation을 추가하는 정책으로 설정됩니다.
[controller.kubernetes.io/pod-deletion-cost](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost)
어노테이션은 Kubernetes에게 덜 _비싼_ Pod를 먼저 삭제하도록 효과적으로 지시합니다.

작업을 시작해봅시다. Helm을 사용하여 Kyverno를 설치한 다음 아래에 포함된 정책을 배포하겠습니다:

```bash timeout=300 wait=30
$ helm repo add kyverno https://kyverno.github.io/kyverno/
$ helm install kyverno kyverno/kyverno --version 3.3.7 -n kyverno --create-namespace -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/values.yaml

```

아래 `ClusterPolicy` 매니페스트는 Kyverno에게 EKS Hybrid Nodes 인스턴스에
도착하는 Pod를 감시하고 `pod-deletion-cost`
어노테이션을 추가하도록 지시합니다.

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml" paths="spec.rules.0.match, spec.rules.0.context.0, spec.rules.0.context.1, spec.rules.0.preconditions, spec.rules.0.mutate"}

1. `Pod/binding` 리소스를 감시하며, 이 시점에서 Pod가 노드로 스케줄링되었습니다
2. admission review 요청의 해당 값으로 `node` 변수를 설정합니다
3. Pod가 스케줄링된 노드에 대한 정보를 Kubernetes API에 쿼리하여 `computeType` 변수를 설정합니다
4. 'hybrid' 노드로 스케줄링된 Pod만 선택합니다
5. Pod를 수정하여 `pod-deletion-cost` 어노테이션을 추가합니다

Kyverno가 실행 중인지 확인하고 정책을 적용해봅시다:

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready pods --all -n kyverno --timeout=2m
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml
```

이제 샘플 워크로드를 배포하겠습니다. 이는 앞서 논의한 nodeAffinity 규칙을 사용하여 하이브리드 노드에 3개의 nginx Pod를 배치합니다:

```bash timeout=300 wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/deployment.yaml
```

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/deployment.yaml"}

배포가 롤아웃된 후 3개의 nginx-deployment Pod를 볼 수 있으며, 모두
하이브리드 노드에 배포되었습니다. 노드와 어노테이션을 한 번에 모두 볼 수 있도록 kubectl의 사용자 정의 출력을 사용하고 있습니다. Kyverno가 `pod-deletion-cost` 어노테이션을 적용한 것을 볼 수 있습니다!

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```

스케일을 확장하고 클라우드로 버스팅해봅시다! 여기서 nginx 배포는 시연 목적으로
비합리적인 양의 CPU(200m)를 요청하고 있습니다. 이는 하이브리드 노드에
약 8개의 레플리카를 배치할 수 있음을 의미합니다. Pod의 레플리카를 15개로 스케일업하면
스케줄링할 공간이 없습니다. `preferredDuringSchedulingIgnoredDuringExecution` 어피니티 정책을 사용하고 있으므로, 이는
하이브리드 노드로 시작함을 의미합니다. 스케줄링할 수 없는 것은
다른 곳(클라우드 인스턴스)에 스케줄링될 수 있습니다.

일반적으로 스케일링은 CPU, 메모리, GPU 가용성 또는
큐 깊이와 같은 외부 요인에 따라 자동으로 이루어집니다. 여기서는 스케일업을 강제로 수행하겠습니다:

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 15
```

이제 사용자 정의 컬럼으로 `kubectl get pods`를 실행하면, 추가 Pod들이
워크샵 EKS 클러스터에 연결된 EC2 인스턴스에 배포된 것을 볼 수 있습니다. Kyverno는
하이브리드 노드에 배치된 모든 Pod에 `pod-deletion-cost` 어노테이션을 적용했고,
EC2에 배치된 모든 Pod에는 이를 적용하지 않았습니다. 스케일을 다시 줄이면 Kubernetes는 먼저 모든 _저렴한_ Pod, 즉 비용이 없는 Pod를 삭제할 것입니다. 그러면 Kubernetes는 나머지를 모두 동등하게 보고 일반적인 삭제 로직이 작동합니다. 이제 실제로 확인해봅시다:

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                                          ANNOTATIONS
nginx-deployment-7474978d4f-8269p   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-8f6cg   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-bjbvx   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-f55rj   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-jrcsl   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-mstwv   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-q8nkj   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-smc9f   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-ss76l   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-tbzf2   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-txxlw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-wqbsd   ip-10-42-154-155.us-west-2.compute.internal   <none>
```

샘플 배포를 다시 3개로 스케일 다운해봅시다. 하이브리드 노드에서 실행 중인 3개의 Pod만 남게 되어 원래 상태로 돌아갑니다:

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 3
```

마지막으로, 확실히 하기 위해 하이브리드 노드에서 실행 중인 레플리카가 3개로 줄어들었는지 확인해봅시다:

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```

