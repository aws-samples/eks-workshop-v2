---
title: "LLM 워크로드를 위한 노드 풀 프로비저닝"
sidebar_position: 20
---

이 실습에서는 Karpenter를 사용하여 Llama2 챗봇 워크로드를 처리하는 데 필요한 Inferentia-2 노드를 프로비저닝할 것입니다. 오토스케일러로서 Karpenter는 머신 러닝 워크로드를 실행하고 트래픽을 효율적으로 분산하는 데 필요한 리소스를 생성합니다.

:::tip
Karpenter에 대해 더 자세히 알아보려면 이 워크샵의 [Karpenter 모듈](../../autoscaling/compute/karpenter/index.md)을 확인하세요.
:::

Karpenter는 이미 EKS 클러스터에 설치되어 있으며 deployment로 실행됩니다:

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

Ray 클러스터가 다양한 EC2 패밀리를 처리하기 위해 서로 다른 사양의 헤드 및 워커 파드를 생성하므로, 워크로드 요구사항을 처리하기 위해 두 개의 별도 노드 풀을 생성할 것입니다.

다음은 `x86 CPU` 인스턴스에서 하나의 `Head Pod`를 프로비저닝할 첫 번째 Karpenter `NodePool`입니다:

::yaml{file="manifests/modules/aiml/chatbot/nodepool/nodepool-x86.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.limits"}

1. `NodePool`에게 모든 새로운 노드를 `type: karpenter` Kubernetes 레이블로 시작하도록 요청하고 있습니다. 이를 통해 데모 목적으로 특정 Karpenter 노드에 파드를 타겟팅할 수 있습니다. Karpenter에 의해 여러 노드가 오토스케일링되므로 `instanceType: mixed-x86`과 같은 추가 레이블이 추가되어 이 Karpenter 노드가 `x86-cpu-karpenter` 풀에 할당되어야 함을 나타냅니다.
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)는 인스턴스 유형 및 영역과 같은 노드 속성을 정의할 수 있습니다. 이 예제에서는 `karpenter.sh/capacity-type`을 설정하여 Karpenter가 온디맨드 및 스팟 인스턴스만 프로비저닝하도록 초기 제한하고, `karpenter.k8s.aws/instance-family`를 설정하여 특정 인스턴스 유형의 하위 집합으로 제한합니다. [여기서](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes) 사용 가능한 다른 속성들을 확인할 수 있습니다. 이전 실습과 비교하여 `r5`, `m5`, `c5` 노드의 인스턴스 패밀리를 정의하는 등 `Head Pod`의 고유한 제약 조건을 정의하는 더 많은 사양이 있습니다.
3. `NodePool`은 관리하는 CPU와 메모리 양에 제한을 정의할 수 있습니다. 이 제한에 도달하면 Karpenter는 해당 `NodePool`과 관련된 추가 용량을 프로비저닝하지 않아 전체 컴퓨팅에 대한 상한선을 제공합니다.

이 두 번째 `NodePool`은 `Inf2.48xlarge` 인스턴스에서 `Ray Workers`를 프로비저닝할 것입니다:

::yaml{file="manifests/modules/aiml/chatbot/nodepool/nodepool-inf2.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. `NodePool`에게 모든 새로운 노드를 `provisionerType: Karpenter` Kubernetes 레이블로 시작하도록 요청하고 있습니다. 이를 통해 데모 목적으로 특정 Karpenter 노드에 파드를 타겟팅할 수 있습니다. Karpenter에 의해 여러 노드가 오토스케일링되므로 `instanceType: inferentia-inf2`와 같은 추가 레이블이 추가되어 이 Karpenter 노드가 `inferentia-inf2` 풀에 할당되어야 함을 나타냅니다.
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)는 인스턴스 유형 및 영역과 같은 노드 속성을 정의할 수 있습니다. 이 예제에서는 `karpenter.sh/capacity-type`을 설정하여 Karpenter가 온디맨드 및 스팟 인스턴스만 프로비저닝하도록 초기 제한하고, `karpenter.k8s.aws/instance-family`를 설정하여 특정 인스턴스 유형의 하위 집합으로 제한합니다. [여기서](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes) 사용 가능한 다른 속성들을 확인할 수 있습니다. 이 경우 `Inf2` 패밀리의 인스턴스에서 실행될 `Ray Workers`의 요구사항과 일치하는 사양이 있습니다.
3. `Taint`는 노드가 일련의 파드를 거부할 수 있게 하는 특정 속성 집합을 정의합니다. 이 속성은 매칭되는 레이블인 `Toleration`과 함께 작동합니다. 톨러레이션과 테인트는 함께 작동하여 파드가 적절한 파드에 올바르게 스케줄링되도록 보장합니다. [이 리소스](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)에서 다른 속성들에 대해 자세히 알아볼 수 있습니다.
4. `NodePool`은 관리하는 CPU와 메모리 양에 제한을 정의할 수 있습니다. 이 제한에 도달하면 Karpenter는 해당 `NodePool`과 관련된 추가 용량을 프로비저닝하지 않아 전체 컴퓨팅에 대한 상한선을 제공합니다.

이렇게 정의된 두 노드 풀을 통해 Karpenter는 노드를 적절히 스케줄링하고 Ray 클러스터의 워크로드 요구사항을 처리할 수 있습니다.

두 풀 모두에 대해 `NodePool` 및 `EC2NodeClass` 매니페스트를 적용하세요:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/inferentia-inf2 created
ec2nodeclass.karpenter.k8s.aws/x86-cpu-karpenter created
nodepool.karpenter.sh/inferentia-inf2 created
nodepool.karpenter.sh/x86-cpu-karpenter created
```

제대로 배포되었다면 노드 풀을 확인하세요:

```bash
$ kubectl get nodepool
NAME                NODECLASS
inferentia-inf2     inferentia-inf2
x86-cpu-karpenter   x86-cpu-karpenter
```

위 명령에서 볼 수 있듯이, 두 노드 풀이 제대로 프로비저닝되어 Karpenter가 필요에 따라 새로 생성된 풀에 새 노드를 할당할 수 있습니다.