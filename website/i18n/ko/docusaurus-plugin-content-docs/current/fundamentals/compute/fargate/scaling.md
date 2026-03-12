---
title: 워크로드 스케일링
sidebar_position: 30
tmdTranslationSourceHash: '6c2730f893e1af352a91566144abe7b7'
---

Fargate의 또 다른 이점은 제공하는 단순화된 수평 스케일링 모델입니다. 컴퓨팅에 EC2를 사용할 때 Pod 스케일링은 Pod 자체뿐만 아니라 기본 컴퓨팅도 어떻게 스케일링할지 고려해야 합니다. Fargate는 기본 컴퓨팅을 추상화하므로 Pod 자체 스케일링에만 집중하면 됩니다.

지금까지 살펴본 예제들은 단일 Pod 레플리카만 사용했습니다. 실제 시나리오에서 일반적으로 예상되는 것처럼 이를 수평으로 스케일 아웃하면 어떻게 될까요? `checkout` 서비스를 스케일 업하고 확인해 봅시다:

```kustomization
modules/fundamentals/fargate/scaling/deployment.yaml
Deployment/checkout
```

kustomization을 적용하고 롤아웃이 완료될 때까지 기다립니다:

```bash timeout=240
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/scaling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

롤아웃이 완료되면 Pod 개수를 확인할 수 있습니다:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-2c75m   1/1     Running   0          2m12s
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

이러한 각 Pod는 별도의 Fargate 인스턴스에서 스케줄링됩니다. 이전과 유사한 단계를 수행하고 특정 Pod의 노드를 식별하여 이를 확인할 수 있습니다.

