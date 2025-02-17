---
title: "Karpenter 설정"
sidebar_position: 20
---

이 섹션에서는 Inferentia와 Trainium EC2 인스턴스를 생성할 수 있도록 Karpenter를 구성할 것입니다. Karpenter는 inf2 또는 trn1 인스턴스가 필요한 대기 중인 Pod들을 감지할 수 있습니다. Karpenter는 그런 다음 Pod를 스케줄링하기 위해 필요한 인스턴스를 시작합니다.

:::tip
이 워크샵에서 제공하는 [Karpenter 모듈](../../autoscaling/compute/karpenter/index.md)에서 Karpenter에 대해 더 자세히 알아볼 수 있습니다.
:::

Karpenter는 우리의 EKS 클러스터에 설치되어 있으며, 디플로이먼트로 실행됩니다:

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

Karpenter는 노드를 프로비저닝하기 위해 `NodePool`이 필요합니다. 다음은 우리가 생성할 Karpenter `NodePool`입니다:

::yaml{file="manifests/modules/aiml/inferentia/nodepool/nodepool.yaml" paths="spec.template.spec.requirements.1,spec.template.spec.requirements.1.values"}

1. 이 섹션에서는 이 NodePool이 프로비저닝할 수 있는 인스턴스를 지정합니다
2. 여기서 볼 수 있듯이 이 NodePool은 inf2와 trn1 인스턴스만 생성할 수 있도록 구성되어 있습니다

`NodePool`과 `EC2NodeClass` 매니페스트를 적용하세요:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/nodepool \
  | envsubst | kubectl apply -f-
```

이제 NodePool이 우리의 훈련과 추론 Pod들을 생성할 준비가 되었습니다.