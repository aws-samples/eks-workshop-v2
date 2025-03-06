---
title: 워크로드 확장
sidebar_position: 30
---
Fargate의 또 다른 이점은 단순화된 수평 확장 모델을 제공한다는 것입니다. EC2를 컴퓨팅에 사용할 때, Pod를 확장하려면 Pod 자체뿐만 아니라 기본 컴퓨팅 리소스도 고려해야 합니다. Fargate는 기본 컴퓨팅을 추상화하기 때문에 Pod 자체의 확장만 고려하면 됩니다.

지금까지 살펴본 예제들은 단일 Pod 복제본만 사용했습니다. 실제 시나리오에서 일반적으로 예상되는 대로 이를 수평으로 확장하면 어떻게 될까요? `checkout` 서비스를 확장해 보겠습니다:

```kustomization
modules/fundamentals/fargate/scaling/deployment.yaml
Deployment/checkout
```

kustomization을 적용하고 롤아웃이 완료될 때까지 기다리세요:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/scaling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

롤아웃이 완료되면 Pod의 수를 확인할 수 있습니다:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-2c75m   1/1     Running   0          2m12s
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

이러한 각 Pod는 별도의 Fargate 인스턴스에 스케줄링됩니다. 이전과 유사한 단계를 따라 주어진 Pod의 노드를 식별하여 이를 확인할 수 있습니다.
