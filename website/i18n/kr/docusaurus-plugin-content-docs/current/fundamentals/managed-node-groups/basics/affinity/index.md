---
title: Pod 선호(Affinity)와 비선호(Anti-affinity)
sidebar_position: 30
---
Pod는 특정 노드에서 또는 특정 상황에서만 실행되도록 제한될 수 있습니다. 이는 노드당 하나의 애플리케이션 Pod만 실행하거나, Pod를 노드에서 쌍으로 실행하려는 경우를 포함할 수 있습니다. 또한 노드 어피니티를 사용할 때 Pod는 선호하는 또는 필수적인 제한을 가질 수 있습니다.

이 수업에서는 `checkout-redis` Pod를 노드당 하나의 인스턴스만 실행하고 `checkout` Pod를 `checkout-redis` Pod가 존재하는 노드에서만 하나의 인스턴스를 실행하도록 스케줄링하여,  Pod 간 어피니티와 안티-어피니티에 중점을 둘 것입니다. 이를 통해 캐싱 Pod(`checkout-redis`)가 최상의 성능을 위해 `checkout`  Pod 인스턴스와 로컬로 실행되도록 보장할 것입니다.

먼저 `checkout`과 `checkout-redis` Pod가 실행 중인지 확인해보겠습니다:

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-vzkzw         1/1     Running   0          125m
checkout-redis-6cfd7d8787-kxs8r   1/1     Running   0          127m
```

클러스터에서 두 애플리케이션 모두 하나의 Pod가 실행 중인 것을 볼 수 있습니다. 이제 이들이 어디서 실행되고 있는지 알아보겠습니다:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-698856df4d-vzkzw       ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

위의 결과를 보면, `checkout-698856df4d-vzkzw` Pod는 `ip-10-42-11-142.us-west-2.compute.internal` 노드에서 실행 중이고, `checkout-redis-6cfd7d8787-kxs8r` Pod는 `ip-10-42-10-225.us-west-2.compute.internal` 노드에서 실행 중입니다.

:::note
여러분의 환경에서는 처음에 Pod들이 같은 노드에서 실행될 수 있습니다.
:::

`checkout` 배포에 `podAffinity`와 `podAntiAffinity` 정책을 설정하여 노드당 하나의 `checkout` Pod가 실행되고, `checkout-redis` Pod가 이미 실행 중인 노드에서만 실행되도록 하겠습니다. 이를 선호하는 동작이 아닌 필수 요구사항으로 만들기 위해 `requiredDuringSchedulingIgnoredDuringExecution`을 사용할 것입니다.

다음 kustomization은 **podAffinity**와 **podAntiAffinity** 정책을 모두 지정하는 `affinity` 섹션을 `checkout` 배포에 추가합니다:

```kustomization
modules/fundamentals/affinity/checkout/checkout.yaml
Deployment/checkout
```

변경을 적용하기 위해 다음 명령을 실행하여 클러스터의 `checkout` 배포를 수정합니다:

```bash
$ kubectl delete -n checkout deployment checkout
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/affinity/checkout/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
$ kubectl rollout status deployment/checkout \
  -n checkout --timeout 180s
```

**podAffinity** 섹션은 노드에 `checkout-redis` Pod가 이미 실행 중임을 보장합니다 — 이는 `checkout` Pod가 올바르게 실행되기 위해 `checkout-redis`가 필요하다고 가정하기 때문입니다. **podAntiAffinity** 섹션은 **`app.kubernetes.io/component=service`** 레이블을 매칭하여 노드에 `checkout` Pod가 이미 실행 중이지 않도록 요구합니다. 이제 구성이 작동하는지 확인하기 위해 배포를 확장해보겠습니다:

```bash
$ kubectl scale -n checkout deployment/checkout --replicas 2
```

이제 각 Pod가 어디서 실행되고 있는지 확인합니다:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-6c7c9cdf4f-p5p6q       ip-10-42-10-120.us-west-2.compute.internal
checkout-6c7c9cdf4f-wwkm4
checkout-redis-6cfd7d8787-gw59j ip-10-42-10-120.us-west-2.compute.internal
```

이 예시에서 첫 번째 `checkout` Pod는 우리가 설정한 **podAffinity** 규칙을 충족하므로 기존 `checkout-redis` Pod와 같은 Pod에서 실행됩니다. 두 번째는 아직 대기 중인데, 이는 우리가 정의한 **podAntiAffinity** 규칙이 같은 노드에서 두 개의 `checkout` Pod가 시작되는 것을 허용하지 않기 때문입니다. 두 번째 노드에는 `checkout-redis` Pod가 실행되고 있지 않기 때문에 대기 상태로 유지됩니다.

다음으로, 두 노드를 위해 `checkout-redis`를 두 개의 인스턴스로 확장하겠지만, 먼저 각 노드에 `checkout-redis` 인스턴스를 분산시키기 위해 `checkout-redis` 배포 정책을 수정하겠습니다. 이를 위해 **podAntiAffinity**규칙만 생성하면 됩니다.

```kustomization
modules/fundamentals/affinity/checkout-redis/checkout-redis.yaml
Deployment/checkout-redis
```

다음 명령으로 적용합니다:

```bash
$ kubectl delete -n checkout deployment checkout-redis
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/affinity/checkout-redis/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout unchanged
deployment.apps/checkout-redis configured
$ kubectl rollout status deployment/checkout-redis \
  -n checkout --timeout 180s
```

**podAntiAffinity** 섹션은 `app.kubernetes.io/component=redis` 레이블을 매칭하여 노드에 `checkout-redis` Pod가 이미 실행 중이지 않도록 요구합니다.

```bash
$ kubectl scale -n checkout deployment/checkout-redis --replicas 2
```

실행 중인 Pod를 확인하여 각각 두 개씩 실행 중인지 확인합니다:

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-6ddwn        1/1     Running   0          4m14s
checkout-5b68c8cddf-rd7xf        1/1     Running   0          4m12s
checkout-redis-7979df659-cjfbf   1/1     Running   0          19s
checkout-redis-7979df659-pc6m9   1/1     Running   0          22s
```

또한 Pod가 실행되는 위치를 확인하여 **podAffinity**와 **podAntiAffinity** 정책이 준수되고 있는지 확인할 수 있습니다:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-7979df659-57xcb  ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-7979df659-r7kkm  ip-10-42-12-31.us-west-2.compute.internal
```

Pod 스케줄링이 모두 잘 되어 보이지만, 세 번째 Pod가 어디에 배포될지 보기 위해 `checkout` Pod를 다시 한 번 확장하여 추가로 확인할 수 있습니다:

```bash
$ kubectl scale --replicas=3 deployment/checkout --namespace checkout
```

실행 중인 Pod를 확인하면 두 개의 노드에 이미 Pod가 배포되어 있고 세 번째 노드에는`checkout-redis` Pod가 실행되고 있지 않기 때문에 세 번째 `checkout` Pod가 `Pending` 상태로 있는 것을 볼 수 있습니다.

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-bn8bp        1/1     Running   0          4m59s
checkout-5b68c8cddf-clnps        1/1     Running   0          6m9s
checkout-5b68c8cddf-lb69n        0/1     Pending   0          6s
checkout-redis-7979df659-57xcb   1/1     Running   0          35s
checkout-redis-7979df659-r7kkm   1/1     Running   0          2m10s
```

`Pending` Pod를 제거하여 이 섹션을 마무리 하겠습니다:

```bash
$ kubectl scale --replicas=2 deployment/checkout --namespace checkout
```
