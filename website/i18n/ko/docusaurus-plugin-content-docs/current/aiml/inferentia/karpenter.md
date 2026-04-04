---
title: "컴퓨팅 프로비저닝"
sidebar_position: 20
tmdTranslationSourceHash: 'd9edd002353264f2076e74e0beb7b296'
---

이 섹션에서는 Inferentia 및 Trainium EC2 인스턴스 생성을 허용하도록 Karpenter를 구성합니다. Karpenter는 inf2 또는 trn1 인스턴스가 필요한 대기 중인 Pod를 감지할 수 있습니다. 그런 다음 Karpenter는 Pod를 스케줄링하는 데 필요한 인스턴스를 시작합니다.

:::tip
이 워크샵에서 제공하는 [Karpenter 모듈](../../fundamentals/compute/karpenter/index.md)에서 Karpenter에 대해 자세히 알아볼 수 있습니다.
:::

Karpenter는 EKS 클러스터에 설치되어 있으며 Deployment로 실행됩니다:

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

Karpenter가 노드를 프로비저닝하려면 `NodePool`이 필요합니다. 다음은 우리가 생성할 Karpenter `NodePool`입니다:

::yaml{file="manifests/modules/aiml/inferentia/nodepool/nodepool.yaml" paths="spec.template.spec.requirements.1,spec.template.spec.requirements.1.values"}

1. 이 섹션에서 이 NodePool이 프로비저닝할 수 있는 인스턴스를 지정합니다
2. 여기에서 이 NodePool이 inf2 및 trn1 인스턴스 생성만 허용하도록 구성한 것을 볼 수 있습니다

`NodePool` 및 `EC2NodeClass` 매니페스트를 적용합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/nodepool \
  | envsubst | kubectl apply -f-
```

이제 NodePool은 트레이닝 및 추론 Pod 생성을 위한 준비가 완료되었습니다.

