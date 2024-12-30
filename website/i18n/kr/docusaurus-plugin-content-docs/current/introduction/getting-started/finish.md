---
title: 기타 컴포넌트
sidebar_position: 50
---

이 실습에서는 Kustomize의 기능을 활용하여 나머지 샘플 애플리케이션을 효율적으로 배포할 것입니다. 다음 `kustomization` 파일은 다른 `kustomization`을 참조하고 여러 컴포넌트를 함께 배포하는 방법을 보여줍니다:

```file
manifests/base-application/kustomization.yaml
```

:::tip
`catalog` API가 이 `kustomization`에 있는 것을 보셨나요? 이미 배포하지 않았나요? Kubernetes는 선언적 메커니즘을 사용하기 때문에 `catalog` API의 매니페스트를 다시 적용해도 모든 리소스가 이미 생성되어 있어서 Kubernetes는 아무 작업도 수행하지 않을 것입니다.\
:::

이 `kustomization`을 클러스터에 적용하여 나머지 컴포넌트들을 배포하세요:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

완료되면 `kubectl wait`를 사용하여 진행하기 전에 모든 컴포넌트가 시작되었는지 확인할 수 있습니다:

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

이제 각 애플리케이션 컴포넌트에 대한 Namespace가 생성됩니다:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
assets     Active   62s
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
rabbitmq   Active   62s
ui         Active   62s
```

컴포넌트들을 위해 생성된 모든 Deployment도 확인할 수 있습니다:

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME             READY   UP-TO-DATE   AVAILABLE   AGE
assets      assets           1/1     1            1           90s
carts       carts            1/1     1            1           90s
carts       carts-dynamodb   1/1     1            1           90s
catalog     catalog          1/1     1            1           7m46s
checkout    checkout         1/1     1            1           90s
checkout    checkout-redis   1/1     1            1           90s
orders      orders           1/1     1            1           90s
orders      orders-mysql     1/1     1            1           90s
ui          ui               1/1     1            1           90s
```

이제 샘플 애플리케이션이 배포되었고 이 워크샵의 나머지 실습에서 사용할 기반이 준비되었습니다!

:::tip
Kustomize에 대해 더 자세히 알고 싶다면 이 워크샵에서 제공하는 [선택적 모듈](../kustomize/index.md)을 살펴보세요
:::