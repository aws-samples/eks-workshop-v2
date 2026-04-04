---
title: "컴퓨팅 프로비저닝"
sidebar_position: 30
tmdTranslationSourceHash: '915504d242c85876aecddbded1a5714a'
---

이 실습에서는 Karpenter를 사용하여 가속화된 머신러닝 추론을 위해 특별히 설계된 AWS Neuron 노드를 프로비저닝합니다. Inferentia와 Trainium은 AWS의 전용 ML 가속기로, Mistral-7B 모델과 같은 추론 워크로드를 실행하는 데 높은 성능과 비용 효율성을 제공합니다.

:::tip
Karpenter에 대해 자세히 알아보려면 이 워크샵의 [Karpenter 모듈](../../fundamentals/compute/karpenter/index.md)을 확인하세요.
:::

Karpenter는 이미 EKS 클러스터에 설치되어 있으며 Deployment로 실행됩니다:

```bash
$ kubectl get deployment karpenter -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

Neuron 인스턴스를 프로비저닝하는 데 사용할 Karpenter NodePool의 구성을 살펴보겠습니다:

::yaml{file="manifests/modules/aiml/chatbot/nodepool.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. 실행 중인 리전에서 사용 가능한 항목에 따라 `inf2.xlarge` 또는 `trn1.2xlarge` 인스턴스 유형을 사용하도록 NodePool을 구성하고 있습니다.
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)는 인스턴스 유형 및 영역과 같은 노드 속성 정의를 지원합니다. 이 예제에서는 `karpenter.sh/capacity-type`을 설정하여 Karpenter가 초기에 On-Demand 인스턴스를 프로비저닝하도록 제한하고, `karpenter.k8s.aws/instance-type`을 설정하여 특정 인스턴스 유형의 하위 집합으로 제한합니다. 사용 가능한 다른 속성은 [여기](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes)에서 확인할 수 있습니다.
3. Taint는 노드가 특정 Pod 집합을 거부할 수 있도록 하는 특정 속성 집합을 정의합니다. 이 속성은 일치하는 레이블인 Toleration과 함께 작동합니다. Toleration과 Taint는 함께 작동하여 Pod가 적절한 노드에 올바르게 스케줄링되도록 합니다. 다른 속성에 대한 자세한 내용은 [이 리소스](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)에서 확인할 수 있습니다.
4. NodePool은 관리하는 CPU 및 메모리 양에 대한 제한을 정의할 수 있습니다. 이 제한에 도달하면 Karpenter는 해당 특정 NodePool과 관련된 추가 용량을 프로비저닝하지 않으며, 전체 컴퓨팅에 상한선을 제공합니다.

NodePool을 생성해 보겠습니다:

```bash
$ cat ~/environment/eks-workshop/modules/aiml/chatbot/nodepool.yaml \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/neuron created
nodepool.karpenter.sh/neuron created
```

제대로 배포되면 NodePool을 확인합니다:

```bash
$ kubectl get nodepool
NAME         NODECLASS    NODES   READY   AGE
neuron       neuron       0       True    31s
```

위 명령에서 볼 수 있듯이 NodePool이 제대로 프로비저닝되어 Karpenter가 필요에 따라 새 노드를 프로비저닝할 수 있습니다. 다음 단계에서 ML 워크로드를 배포하면 Karpenter는 지정한 리소스 요청 및 제한에 따라 필요한 Neuron 인스턴스를 자동으로 생성합니다.

